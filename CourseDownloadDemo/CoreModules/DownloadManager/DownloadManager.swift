// DownloadManager.swift
import Foundation
import Combine
import OSLog

// Custom error type to avoid external dependencies
enum DownloadError: Error, LocalizedError {
    case taskNotFound(String)
    case fileOperationFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .taskNotFound(let message):
            return message
        case .fileOperationFailed(let message):
            return message
        }
    }
}

final class DownloadManager: DownloadManagerProtocol {
    // MARK: - Properties
    private let networkClient: NetworkClientProtocol
    private let fileManager: FileManagerProtocol
    private let logger: Logger
    private var sessionDelegate: NetworkSessionDelegate?
    
    private var downloadTasks: [UUID: DownloadTaskInfo] = [:]
    private let progressSubject = PassthroughSubject<(UUID, Double), Never>()
    private let stateChangeSubject = PassthroughSubject<(UUID, DownloadState), Never>()
    private let downloadCompletionSubject = PassthroughSubject<(UUID, URL), Never>()
    
    // MARK: - Protocol Requirements
    var downloadProgress: AnyPublisher<(UUID, Double), Never> {
        progressSubject.eraseToAnyPublisher()
    }
    
    var downloadStateChange: AnyPublisher<(UUID, DownloadState), Never> {
        stateChangeSubject.eraseToAnyPublisher()
    }
    
    var downloadCompletion: AnyPublisher<(UUID, URL), Never> {
        downloadCompletionSubject.eraseToAnyPublisher()
    }
    
    // MARK: - Initialization
    init(
        networkClient: NetworkClientProtocol,
        fileManager: FileManagerProtocol,
        backgroundCompletionHandler: (() -> Void)? = nil,
        logger: Logger = Logger(subsystem: "com.app.CourseDownloader", category: "DownloadManager")
    ) {
        self.networkClient = networkClient
        self.fileManager = fileManager
        self.logger = logger
        
        // Create and configure delegate
        self.sessionDelegate = NetworkSessionDelegate(downloadManager: self)
        networkClient.configureBGSessionWithDelegate(sessionDelegate!)
        
        // Store background completion handler in DIContainer
        if let handler = backgroundCompletionHandler {
            DIContainer.shared.backgroundCompletionHandler = handler
        }
    }
    
    // MARK: - Protocol Methods
    func startDownload(id: UUID, url: URL, fileName: String, fileType: String) async throws {
        // Check if already downloading
        if let existingTask = downloadTasks[id] {
            // If paused, resume it
            if existingTask.task.state == .suspended {
                try await resumeDownload(id: id)
            }
            return
        }
        
        // CRITICAL: Ensure delegate is configured before creating task
        if sessionDelegate == nil {
            logger.error("Session delegate not configured! Setting it up now.")
            self.sessionDelegate = NetworkSessionDelegate(downloadManager: self)
            networkClient.configureBGSessionWithDelegate(sessionDelegate!)
        }
        
        // Create new download task
        let (task, progress) = networkClient.downloadWithProgress(url: url)
        
        // CRITICAL: Set task description BEFORE starting the task
        task.taskDescription = id.uuidString
        
        logger.info("Created download task with description: \(task.taskDescription ?? "nil")")
        
        // Observe progress with weak self to avoid retain cycle
        let progressObserver = progress.observe(\.fractionCompleted, options: [.new]) { [weak self] progress, _ in
            guard let self = self else { return }
            
            let fractionCompleted = progress.fractionCompleted
            self.logger.debug("Progress update for \(id.uuidString): \(Int(fractionCompleted * 100))%")
            self.progressSubject.send((id, fractionCompleted))
            
            // FAIL-SAFE: If progress reaches 100% but completion hasn't been called
            if fractionCompleted >= 1.0 {
                self.logger.warning("Download progress reached 100% for \(id.uuidString), checking if completion was missed")
                
                // Give the delegate a moment to fire
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                    guard let self = self else { return }
                    
                    // Check if this download is still in our active tasks
                    if let taskInfo = self.downloadTasks[id], taskInfo.task.state == .completed {
                        self.logger.warning("Download completed but delegate wasn't called for \(id.uuidString)")
                        
                        // Check if we can find the downloaded file
                        if let response = taskInfo.task.response,
                           let suggestedFilename = response.suggestedFilename {
                            
                            // Try to find the file in temp directory
                            let tempDir = self.fileManager.temporaryDirectory
                            let possiblePaths = [
                                tempDir.appendingPathComponent(suggestedFilename),
                                tempDir.appendingPathComponent("CFNetworkDownload_\(suggestedFilename)")
                            ]
                            
                            for path in possiblePaths {
                                if self.fileManager.fileExists(atPath: path.path) {
                                    self.logger.info("Found completed download at \(path.path)")
                                    Task {
                                        await self.handleDownloadCompletion(id: id, tempURL: path)
                                    }
                                    return
                                }
                            }
                        }
                        
                        // If we can't find the file, mark as failed
                        self.logger.error("Download completed but file not found for \(id.uuidString)")
                        self.stateChangeSubject.send((id, .failed))
                        self.cleanupTask(id: id)
                    }
                }
            }
        }
        
        let taskInfo = DownloadTaskInfo(
            id: id,
            task: task,
            progress: progress,
            fileName: fileName,
            fileType: fileType,
            progressObserver: progressObserver
        )
        
        downloadTasks[id] = taskInfo
        task.resume()
        
        stateChangeSubject.send((id, .downloading))
        logger.info("Started download for \(id.uuidString)")
    }
    
    func pauseDownload(id: UUID) async throws {
        guard let taskInfo = downloadTasks[id] else {
            throw DownloadError.taskNotFound("No active download found for id: \(id)")
        }
        
        taskInfo.task.suspend()
        stateChangeSubject.send((id, .paused))
        logger.info("Paused download for \(id.uuidString)")
    }
    
    func resumeDownload(id: UUID) async throws {
        guard let taskInfo = downloadTasks[id] else {
            throw DownloadError.taskNotFound("No paused download found for id: \(id)")
        }
        
        taskInfo.task.resume()
        stateChangeSubject.send((id, .downloading))
        logger.info("Resumed download for \(id.uuidString)")
    }
    
    func cancelDownload(id: UUID) async throws {
        guard let taskInfo = downloadTasks[id] else {
            // Not an error if task doesn't exist
            logger.info("No task to cancel for \(id.uuidString)")
            return
        }
        
        taskInfo.task.cancel()
        cleanupTask(id: id)
        stateChangeSubject.send((id, .notDownloaded))
        logger.info("Cancelled download for \(id.uuidString)")
    }
    
    func deleteDownload(id: UUID) async throws {
        // Cancel if currently downloading
        if downloadTasks[id] != nil {
            try await cancelDownload(id: id)
        }
        
        // Delete downloaded file if it exists
        let directory = fileManager.getDownloadsDirectory().appendingPathComponent(id.uuidString)
        
        if fileManager.fileExists(atPath: directory.path) {
            do {
                try fileManager.removeItem(at: directory)
                stateChangeSubject.send((id, .notDownloaded))
                logger.info("Deleted download for \(id.uuidString)")
            } catch {
                throw DownloadError.fileOperationFailed("Failed to delete file: \(error.localizedDescription)")
            }
        }
    }
    
    func isDownloading(id: UUID) -> Bool {
        return downloadTasks[id] != nil
    }
    
    func getActiveDownloads() async -> [UUID] {
        return Array(downloadTasks.keys)
    }
    
    // MARK: - Internal Methods for NetworkSessionDelegate
    func handleDownloadCompletion(id: UUID, tempURL: URL) async {
        defer {
            // Always clean up temp file
            try? fileManager.removeItem(at: tempURL)
        }
        
        guard let taskInfo = downloadTasks[id] else {
            logger.warning("No task info found for completed download \(id.uuidString)")
            return
        }
        
        do {
            // Create directory for this download
            let directory = fileManager.getDownloadsDirectory().appendingPathComponent(id.uuidString)
            try fileManager.createDirectory(at: directory, withIntermediateDirectories: true, attributes: nil)
            
            // Generate unique filename
            let baseFileName = "\(taskInfo.fileName).\(taskInfo.fileType)"
            let uniqueFileName = fileManager.getUniqueFileName(originalName: baseFileName, inDirectory: directory)
            let destinationURL = directory.appendingPathComponent(uniqueFileName)
            
            // Move file to permanent location
            try fileManager.moveItem(at: tempURL, to: destinationURL)
            
            // Send final progress update
            progressSubject.send((id, 1.0))
            
            // Send completion event with the final URL
            downloadCompletionSubject.send((id, destinationURL))
            
            // Send the state change
            stateChangeSubject.send((id, .downloaded))
            
            logger.info("Download completed for \(id.uuidString) at \(destinationURL.path)")
        } catch {
            stateChangeSubject.send((id, .failed))
            logger.error("Download failed for \(id.uuidString): \(error.localizedDescription)")
        }
        
        cleanupTask(id: id)
    }
    
    func handleDownloadFailure(id: UUID, error: Error?) {
        if let urlError = error as? URLError, urlError.code == .cancelled {
            logger.info("Download cancelled for \(id.uuidString)")
        } else {
            logger.error("Download failed for \(id.uuidString): \(error?.localizedDescription ?? "Unknown error")")
            stateChangeSubject.send((id, .failed))
        }
        
        cleanupTask(id: id)
    }
    
    // MARK: - Private Methods
    private func cleanupTask(id: UUID) {
        downloadTasks[id]?.progressObserver?.invalidate()
        downloadTasks[id] = nil
    }
}
