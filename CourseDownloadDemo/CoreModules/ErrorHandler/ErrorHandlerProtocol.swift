//
//  ErrorHandlerProtocol.swift
//  CourseDownloadDemo
//
//  Created by Kashif Hussain on 10/05/25.
//


// ErrorHandler/ErrorHandlerProtocol.swift
import Foundation
import Combine

protocol ErrorHandlerProtocol {
    var errors: AnyPublisher<AppError, Never> { get }
    
    func handle(_ error: Error)
    func handleNetworkError(_ error: NetworkError)
    func handlePersistenceError(_ message: String)
    func handleFileSystemError(_ message: String)
    func handleParsingError(_ message: String)
}
