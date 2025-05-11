//
//  NetworkSessionDelegate.swift
//  CourseDownloadDemo
//
//  Created by Kashif Hussain on 10/05/25.
//


// NetworkClient/NetworkSessionDelegate.swift
import Foundation

class NetworkSessionDelegate: NSObject, URLSessionDownloadDelegate {
    private weak var client: NetworkClient?
    private let downloadCompletionHandler: (URL, URLSessionDownloadTask) -> Void
    
    init(client: NetworkClient, downloadCompletionHandler: ((URL, URLSessionDownloadTask) -> Void)? = nil) {
        self.client = client
        self.downloadCompletionHandler = downloadCompletionHandler ?? { _, _ in }
        super.init()
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        downloadCompletionHandler(location, downloadTask)
    }
    
    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        client?.backgroundCompletionHandlerCalled()
    }
}
