// NetworkClient.swift
import Foundation
import Combine
import OSLog

final class NetworkClient: NetworkClientProtocol {
    private var session: URLSession?
    private let configuration: URLSessionConfiguration
    private let logger: Logger
    private var sessionDelegate: URLSessionDownloadDelegate?
    
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
        
        // Don't create session yet - wait for delegate to be set
    }
    
    func configureBGSessionWithDelegate(_ delegate: URLSessionDownloadDelegate) {
        self.sessionDelegate = delegate
        self.session = URLSession(configuration: self.configuration, delegate: delegate, delegateQueue: nil)
        logger.info("Configured background session with delegate")
    }
    
    private func getSession() -> URLSession {
        if let session = self.session {
            return session
        }
        
        // Create default session if no delegate was set
        let defaultSession = URLSession(configuration: self.configuration)
        self.session = defaultSession
        return defaultSession
    }
    
    func download(url: URL) async throws -> (URL, URLResponse) {
        do {
            return try await getSession().download(from: url)
        } catch {
            logger.error("Download failed: \(error.localizedDescription)")
            throw mapError(error)
        }
    }
    
    func downloadWithProgress(url: URL) -> (task: URLSessionDownloadTask, progress: Progress) {
        let request = URLRequest(url: url)
        let currentSession = getSession()
        let task = currentSession.downloadTask(with: request)
        let progress = task.progress
        
        logger.info("Created download task for URL: \(url.absoluteString)")
        logger.info("Using session with delegate: \(currentSession.delegate != nil ? "YES" : "NO")")
        
        return (task, progress)
    }
    
    func getAllTasks() async -> [URLSessionTask] {
        return await withCheckedContinuation { continuation in
            getSession().getAllTasks { tasks in
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
