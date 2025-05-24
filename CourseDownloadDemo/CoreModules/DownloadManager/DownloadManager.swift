// DownloadManager.swift
// DownloadManager.swift
// DownloadManager.swift
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
    
    // MARK: - Protocol Requirements
    var downloadProgress: AnyPublisher<(UUID, Double), Never> {
        progressSubject.eraseToAnyPublisher()
    }
    
    var downloadStateChange: AnyPublisher<(UUID, DownloadState), Never> {
        stateChangeSubject.eraseToAnyPublisher()
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
        
        // Create new download task
        let (task, progress) = networkClient.downloadWithProgress(url: url)
        task.taskDescription = id.uuidString
        
        // Observe progress with weak self to avoid retain cycle
        let progressObserver = progress.observe(\.fractionCompleted, options: [.new]) { [weak self] progress, _ in
            self?.progressSubject.send((id, progress.fractionCompleted))
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
            
            // Update state
            stateChangeSubject.send((id, .downloaded))
            
            // Save file location to storage
            await MainActor.run {
                DIContainer.shared.modelStorage.saveDownloadState(
                    id: id,
                    state: .downloaded,
                    progress: 1.0,
                    localURL: destinationURL
                )
            }
            
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
