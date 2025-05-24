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
        guard let moduleID = downloadTask.taskDescription.flatMap({ UUID(uuidString: $0) }),
              let manager = downloadManager else {
            logger.error("Failed to get module ID or manager is nil")
            return
        }
        
        logger.info("Download completed for task with module ID: \(moduleID.uuidString)")
        
        // CRITICAL FIX: Handle the file synchronously within this callback
        // The temporary file at 'location' is only valid during this method call
        let fileManager = FileManager.default
        let tempDir = fileManager.temporaryDirectory
        let safeTempLocation = tempDir.appendingPathComponent(UUID().uuidString)
        
        do {
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
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard let downloadTask = task as? URLSessionDownloadTask,
              let moduleID = downloadTask.taskDescription.flatMap({ UUID(uuidString: $0) }),
              let manager = downloadManager else {
            return
        }
        
        if let error = error {
            logger.error("Download task failed with error: \(error.localizedDescription)")
            Task {
                manager.handleDownloadFailure(id: moduleID, error: error)
            }
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
