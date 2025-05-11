//
//  NetworkError.swift
//  CourseDownloadDemo
//
//  Created by Kashif Hussain on 10/05/25.
//


// MARK: - NetworkClient Module

// NetworkClient/NetworkError.swift
import Foundation

enum NetworkError: Error, Equatable {
    case invalidURL
    case requestFailed(statusCode: Int)
    case noData
    case decodingFailed
    case cancelled
    case unknown(Error)
    
    static func == (lhs: NetworkError, rhs: NetworkError) -> Bool {
        switch (lhs, rhs) {
        case (.invalidURL, .invalidURL):
            return true
        case (.requestFailed(let lhsCode), .requestFailed(let rhsCode)):
            return lhsCode == rhsCode
        case (.noData, .noData):
            return true
        case (.decodingFailed, .decodingFailed):
            return true
        case (.cancelled, .cancelled):
            return true
        case (.unknown, .unknown):
            return true
        default:
            return false
        }
    }
}