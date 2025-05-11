//
//  NetworkSessionDelegate.swift
//  CourseDownloadDemo
//
//  Created by Kashif Hussain on 10/05/25.
//


// NetworkClient/NetworkSessionDelegate.swift
// NetworkSessionDelegate.swift
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
        
        // IMPORTANT: The temporary URL is only valid during this function call
        // We need to immediately copy the file to a safe location
        let tempDir = FileManager.default.temporaryDirectory
        let safeTempLocation = tempDir.appendingPathComponent(UUID().uuidString)
        
        do {
            try FileManager.default.copyItem(at: location, to: safeTempLocation)
            logger.info("Successfully copied download to safe location: \(safeTempLocation.path)")
            
            // Now that we have a safe copy, we can process it asynchronously
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
        DIContainer.shared.backgroundCompletionHandler?()
    }
}
