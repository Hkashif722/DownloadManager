//
//  DownloadManager.swift
//  CourseDownloadDemo
//
//  Created by Kashif Hussain on 10/05/25.
//


// DownloadManager/DownloadManager.swift
import Foundation
import Combine
import OSLog

final class DownloadManager: DownloadManagerProtocol {
    private let networkClient: NetworkClientProtocol
    private let fileManager: FileManagerProtocol
    private let logger: Logger
    
    private var downloadTasks: [UUID: DownloadTaskInfo] = [:]
    private let progressSubject = PassthroughSubject<(UUID, Double), Never>()
    private let stateChangeSubject = PassthroughSubject<(UUID, DownloadState), Never>()
    
    var downloadProgress: AnyPublisher<(UUID, Double), Never> {
        progressSubject.eraseToAnyPublisher()
    }
    
    var downloadStateChange: AnyPublisher<(UUID, DownloadState), Never> {
        stateChangeSubject.eraseToAnyPublisher()
    }
    
    init(networkClient: NetworkClientProtocol, fileManager: FileManagerProtocol, logger: Logger = Logger(subsystem: "com.app.CourseDownloader", category: "DownloadManager")) {
        self.networkClient = networkClient
        self.fileManager = fileManager
        self.logger = logger
    }
    
    func startDownload(id: UUID, url: URL, fileName: String, fileType: String) async {
        if downloadTasks[id] != nil {
            // Already downloading, resume if paused
            resumeDownload(id: id)
            return
        }
        
        let (task, progress) = networkClient.downloadWithProgress(url: url)
        task.taskDescription = id.uuidString
        
        // Observe progress
        let progressObserver = progress.observe(\.fractionCompleted) { [weak self] progress, _ in
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
    
    func pauseDownload(id: UUID) async {
        guard let taskInfo = downloadTasks[id] else {
            logger.warning("No task found to pause for \(id.uuidString)")
            return
        }
        
        taskInfo.task.suspend()
        stateChangeSubject.send((id, .paused))
        logger.info("Paused download for \(id.uuidString)")
    }
    
    func resumeDownload(id: UUID) async {
        guard let taskInfo = downloadTasks[id] else {
            logger.warning("No task found to resume for \(id.uuidString)")
            return
        }
        
        taskInfo.task.resume()
        stateChangeSubject.send((id, .downloading))
        logger.info("Resumed download for \(id.uuidString)")
    }
    
    func cancelDownload(id: UUID) async {
        guard let taskInfo = downloadTasks[id] else {
            logger.warning("No task found to cancel for \(id.uuidString)")
            return
        }
        
        taskInfo.task.cancel()
        cleanupTask(id: id)
        stateChangeSubject.send((id, .notDownloaded))
        logger.info("Cancelled download for \(id.uuidString)")
    }
    
    func deleteDownload(id: UUID) async {
        // If downloading, cancel first
        if let _ = downloadTasks[id] {
            await cancelDownload(id: id)
        }
        
        // Delete local file if it exists
        let directory = fileManager.getDownloadsDirectory().appendingPathComponent(id.uuidString)
        
        if fileManager.fileExists(atPath: directory.path) {
            do {
                try fileManager.removeItem(at: directory)
                stateChangeSubject.send((id, .notDownloaded))
                logger.info("Deleted download for \(id.uuidString)")
            } catch {
                logger.error("Failed to delete file for \(id.uuidString): \(error.localizedDescription)")
            }
        }
    }
    
    func isDownloading(id: UUID) -> Bool {
        return downloadTasks[id] != nil
    }
    
    func getActiveDownloads() async -> [UUID] {
        return Array(downloadTasks.keys)
    }
    
    func handleDownloadCompletion(id: UUID, tempURL: URL) async {
        guard let taskInfo = downloadTasks[id] else {
            logger.warning("No task info found for completed download \(id.uuidString)")
            return
        }
        
        do {
            // Create directory for this download
            let directory = fileManager.getDownloadsDirectory().appendingPathComponent(id.uuidString)
            try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
            
            // Move downloaded file to permanent location
            let destinationURL = directory.appendingPathComponent(taskInfo.fileName)
                .appendingPathExtension(taskInfo.fileType)
            
            try fileManager.moveItem(at: tempURL, to: destinationURL)
            stateChangeSubject.send((id, .downloaded))
            logger.info("Download completed for \(id.uuidString)")
        } catch {
            stateChangeSubject.send((id, .failed))
            logger.error("Download failed for \(id.uuidString): \(error.localizedDescription)")
        }
        
        cleanupTask(id: id)
    }
    
    func handleDownloadFailure(id: UUID, error: Error?) {
        if let error = error {
            logger.error("Download failed for \(id.uuidString): \(error.localizedDescription)")
        } else {
            logger.error("Download failed for \(id.uuidString) with unknown error")
        }
        
        stateChangeSubject.send((id, .failed))
        cleanupTask(id: id)
    }
    
    private func cleanupTask(id: UUID) {
        downloadTasks[id]?.progressObserver?.invalidate()
        downloadTasks[id] = nil
    }
}
