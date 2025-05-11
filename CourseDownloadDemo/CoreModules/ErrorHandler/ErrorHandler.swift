// ErrorHandler/ErrorHandler.swift
import Foundation
import Combine
import OSLog

final class ErrorHandler: ErrorHandlerProtocol {
    private let errorsSubject = PassthroughSubject<AppError, Never>()
    private let logger: Logger
    
    var errors: AnyPublisher<AppError, Never> {
        errorsSubject.eraseToAnyPublisher()
    }
    
    init(logger: Logger = Logger(subsystem: "com.app.CourseDownloader", category: "ErrorHandler")) {
        self.logger = logger
    }
    
    func handle(_ error: Error) {
        if let networkError = error as? NetworkError {
            handleNetworkError(networkError)
        } else {
            let appError = AppError.unknown(error.localizedDescription)
            logger.error("Unknown error: \(error.localizedDescription)")
            errorsSubject.send(appError)
        }
    }
    
    func handleNetworkError(_ error: NetworkError) {
        let appError = AppError.network(error)
        logger.error("Network error: \(error)")
        errorsSubject.send(appError)
    }
    
    func handlePersistenceError(_ message: String) {
        let appError = AppError.persistence(message)
        logger.error("Persistence error: \(message)")
        errorsSubject.send(appError)
    }
    
    func handleFileSystemError(_ message: String) {
        let appError = AppError.fileSystem(message)
        logger.error("File system error: \(message)")
        errorsSubject.send(appError)
    }
}
