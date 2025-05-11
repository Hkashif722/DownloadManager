//
//  AppError.swift
//  CourseDownloadDemo
//
//  Created by Kashif Hussain on 10/05/25.
//


// AppError.swift
import Foundation

enum AppError: Error, Equatable {
    case network(NetworkError)
    case persistence(String)
    case fileSystem(String)
    case parsing(String)
    case unknown(String)
    
    static func == (lhs: AppError, rhs: AppError) -> Bool {
        switch (lhs, rhs) {
        case (.network(let lhsError), .network(let rhsError)):
            return lhsError == rhsError
        case (.persistence(let lhsMessage), .persistence(let rhsMessage)):
            return lhsMessage == rhsMessage
        case (.fileSystem(let lhsMessage), .fileSystem(let rhsMessage)):
            return lhsMessage == rhsMessage
        case (.parsing(let lhsMessage), .parsing(let rhsMessage)):
            return lhsMessage == rhsMessage
        case (.unknown(let lhsMessage), .unknown(let rhsMessage)):
            return lhsMessage == rhsMessage
        default:
            return false
        }
    }
}


