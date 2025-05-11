// Domain/Models/Course.swift
import Foundation
import SwiftData

@Model
final class Course: Identifiable {
    @Attribute(.unique) var id: UUID
    var title: String
    var descriptionText: String
    var thumbnailURL: URL?
    @Relationship(deleteRule: .cascade) var modules: [CourseModule]
    var createdAt: Date
    var updatedAt: Date
    
    init(id: UUID = UUID(), title: String, description: String, thumbnailURL: URL? = nil) {
        self.id = id
        self.title = title
        self.descriptionText = description
        self.thumbnailURL = thumbnailURL
        self.modules = []
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}