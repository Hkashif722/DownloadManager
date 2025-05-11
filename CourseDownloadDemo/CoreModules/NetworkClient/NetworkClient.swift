// NetworkClientProtocol.swift
import Foundation
import Combine



// NetworkClient.swift
import Foundation
import Combine
import OSLog

final class NetworkClient: NetworkClientProtocol {
    private var session: URLSession
    private let configuration: URLSessionConfiguration
    private let logger: Logger
    
    init(
        backgroundIdentifier: String? = nil,
        logger: Logger = Logger(subsystem: "com.app.CourseDownloader", category: "NetworkClient")
    ) {
        self.logger = logger
        
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
    
    func configureBGSessionWithDelegate(_ delegate: URLSessionDownloadDelegate) {
        self.session = URLSession(configuration: self.configuration, delegate: delegate, delegateQueue: nil)
        logger.info("Configured background session with delegate")
    }
    
    func download(url: URL) async throws -> (URL, URLResponse) {
        do {
            return try await session.download(from: url)
        } catch {
            logger.error("Download failed: \(error.localizedDescription)")
            throw mapError(error)
        }
    }
    
    func downloadWithProgress(url: URL) -> (task: URLSessionDownloadTask, progress: Progress) {
        let request = URLRequest(url: url)
        let task = session.downloadTask(with: request)
        let progress = task.progress
        logger.info("Created download task for URL: \(url.absoluteString)")
        return (task, progress)
    }
    
    func getAllTasks() async -> [URLSessionTask] {
        return await withCheckedContinuation { continuation in
            session.getAllTasks { tasks in
                continuation.resume(returning: tasks)
            }
        }
    }
    
    private func mapError(_ error: Error) -> NetworkError {
        if let urlError = error as? URLError {
            switch urlError.code {
            case .cancelled:
                return .cancelled
            case .badURL:
                return .invalidURL
            default:
                return .unknown(urlError)
            }
        } else {
            return .unknown(error)
        }
    }
}
