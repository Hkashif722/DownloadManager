//
//  NetworkSessionDelegate.swift
//  CourseDownloadDemo
//
//  Created by Kashif Hussain on 10/05/25.
//

// NetworkClient/NetworkSessionDelegate.swift
import Foundation
import OSLog

class NetworkSessionDelegate: NSObject, URLSessionDownloadDelegate {
    private weak var downloadManager: DownloadManager?
    private let logger = Logger(subsystem: "com.app.CourseDownloader", category: "NetworkSessionDelegate")
    
    init(downloadManager: DownloadManager) {
        self.downloadManager = downloadManager
        super.init()
        logger.info("NetworkSessionDelegate initialized")
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        logger.info("Download finished callback received for task: \(downloadTask.taskIdentifier)")
        
        // Debug logging
        logger.info("Task description: \(downloadTask.taskDescription ?? "nil")")
        
        guard let taskDescription = downloadTask.taskDescription else {
            logger.error("Download task has no task description")
            return
        }
        
        guard let moduleID = UUID(uuidString: taskDescription) else {
            logger.error("Failed to parse module ID from task description: \(taskDescription)")
            return
        }
        
        guard let manager = downloadManager else {
            logger.error("Download manager is nil")
            return
        }
        
        logger.info("Download completed for module ID: \(moduleID.uuidString)")
        logger.info("Temporary file location: \(location.path)")
        
        // CRITICAL FIX: Handle the file synchronously within this callback
        // The temporary file at 'location' is only valid during this method call
        let fileManager = FileManager.default
        let tempDir = fileManager.temporaryDirectory
        let safeTempLocation = tempDir.appendingPathComponent(UUID().uuidString)
        
        do {
            // Check if source file exists
            if !fileManager.fileExists(atPath: location.path) {
                logger.error("Source file doesn't exist at: \(location.path)")
                return
            }
            
            // Copy immediately while the file is still valid
            try fileManager.copyItem(at: location, to: safeTempLocation)
            logger.info("Successfully copied download to safe location: \(safeTempLocation.path)")
            
            // Now we can safely handle it asynchronously
            Task {
                await manager.handleDownloadCompletion(id: moduleID, tempURL: safeTempLocation)
            }
        } catch {
            logger.error("Failed to create safe copy of downloaded file: \(error)")
            Task {
                manager.handleDownloadFailure(id: moduleID, error: error)
            }
        }
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        guard let taskDescription = downloadTask.taskDescription,
              let moduleID = UUID(uuidString: taskDescription) else {
            return
        }
        
        let progress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
        logger.debug("Download progress for \(moduleID.uuidString): \(Int(progress * 100))%")
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard let downloadTask = task as? URLSessionDownloadTask,
              let moduleID = downloadTask.taskDescription.flatMap({ UUID(uuidString: $0) }),
              let manager = downloadManager else {
            return
        }
        
        if let error = error {
            let urlError = error as NSError
            if urlError.code == NSURLErrorCancelled {
                logger.info("Download was cancelled for module: \(moduleID.uuidString)")
            } else {
                logger.error("Download task failed with error: \(error.localizedDescription)")
            }
            Task {
                manager.handleDownloadFailure(id: moduleID, error: error)
            }
        } else {
            logger.info("Download task completed successfully for module: \(moduleID.uuidString)")
        }
    }
    
    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        logger.info("URLSession did finish events for background session")
        DispatchQueue.main.async {
            DIContainer.shared.backgroundCompletionHandler?()
            DIContainer.shared.backgroundCompletionHandler = nil
        }
    }
}
