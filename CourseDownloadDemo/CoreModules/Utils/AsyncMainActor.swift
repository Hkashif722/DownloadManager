// Utils/AsyncMainActor.swift
import Foundation

@MainActor
struct AsyncMainActor {
    static func run<T>(_ operation: @escaping () async throws -> T) async throws -> T {
        return try await operation()
    }
}