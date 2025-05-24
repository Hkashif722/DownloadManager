//
//  AsyncMainActor.swift
//  CourseDownloadDemo
//
//  Created by Kashif Hussain on 10/05/25.
//


// Utils/AsyncMainActor.swift
import Foundation

@MainActor
struct AsyncMainActor {
    static func run<T>(_ operation: @escaping () async throws -> T) async throws -> T {
        return try await operation()
    }
}

