// PersistenceManager/DownloadRecord.swift
import Foundation
import SwiftData

@Model
final class DownloadRecord {
    var id: UUID
    var state: String
    var progress: Double
    var localURL: URL?
    var createdAt: Date
    var updatedAt: Date
    
    init(id: UUID, state: String, progress: Double, localURL: URL?) {
        self.id = id
        self.state = state
        self.progress = progress
        self.localURL = localURL
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}