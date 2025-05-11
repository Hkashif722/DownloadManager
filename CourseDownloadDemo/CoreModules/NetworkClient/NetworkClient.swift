//
//  NetworkClient.swift
//  CourseDownloadDemo
//
//  Created by Kashif Hussain on 10/05/25.
//


// NetworkClient/NetworkClient.swift
import Foundation
import Combine

final class NetworkClient: NetworkClientProtocol {
    private var session: URLSession
    private let configuration: URLSessionConfiguration
    private var backgroundCompletionHandler: (() -> Void)?
    
    init(backgroundIdentifier: String? = nil) {
        if let identifier = backgroundIdentifier {
            let config = URLSessionConfiguration.background(withIdentifier: identifier)
            config.isDiscretionary = false
            config.sessionSendsLaunchEvents = true
            self.configuration = config
        } else {
            self.configuration = URLSessionConfiguration.default
        }
        
        self.session = URLSession(configuration: self.configuration)
    }
    
    func configureBGSessionWithHandler(_ completionHandler: @escaping () -> Void) {
        self.backgroundCompletionHandler = completionHandler
        let delegate = NetworkSessionDelegate(client: self)
        self.session = URLSession(configuration: self.configuration, delegate: delegate, delegateQueue: nil)
    }
    
    func download(url: URL, toFile destinationURL: URL) async throws {
        do {
            let (downloadedURL, _) = try await session.download(from: url)
            try FileManager.default.moveItem(at: downloadedURL, to: destinationURL)
        } catch {
            throw NetworkError.unknown(error)
        }
    }
    
    func downloadWithProgress(url: URL) -> (task: URLSessionDownloadTask, progress: Progress) {
        let request = URLRequest(url: url)
        let task = session.downloadTask(with: request)
        let progress = task.progress
        return (task, progress)
    }
    
    func getAllTasks() async -> [URLSessionTask] {
        return await withCheckedContinuation { continuation in
            session.getAllTasks { tasks in
                continuation.resume(returning: tasks)
            }
        }
    }
    
    func backgroundCompletionHandlerCalled() {
        backgroundCompletionHandler?()
    }
}
