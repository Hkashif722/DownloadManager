//
//  CourseRepositoryProtocol.swift
//  CourseDownloadDemo
//
//  Created by Kashif Hussain on 10/05/25.
//


// Domain/Services/CourseRepository.swift
import Foundation
import Combine
import OSLog
import SwiftData

protocol CourseRepositoryProtocol {
    func getAllCourses() async throws -> [Course]
    func getCourse(id: UUID) async throws -> Course?
    func saveCourse(_ course: Course) async throws
    func deleteCourse(_ course: Course) async throws
    func getModulesForCourse(id: UUID) async throws -> [CourseModule]
    func verifyDownloadStates() async throws
}

final class CourseRepository: CourseRepositoryProtocol {
   
    private let modelStorage: ModelStorageProtocol
    private let fileManager: FileManagerProtocol
    private let logger: Logger
    
    init(
        modelStorage: ModelStorageProtocol,
        fileManager: FileManagerProtocol,
        logger: Logger = Logger(subsystem: "com.app.CourseDownloader", category: "CourseRepository")
    ) {
        self.modelStorage = modelStorage
        self.fileManager = fileManager
        self.logger = logger
    }
    
    func getAllCourses() async throws -> [Course] {
        return try await AsyncMainActor.run {
            let descriptor = FetchDescriptor<Course>()
            return try self.modelStorage.fetch(descriptor)
        }
    }
    
    func getCourse(id: UUID) async throws -> Course? {
        return try await AsyncMainActor.run {
            let descriptor = FetchDescriptor<Course>(predicate: #Predicate { $0.id == id })
            return try self.modelStorage.fetch(descriptor).first
        }
    }
    
    func saveCourse(_ course: Course) async throws {
        return try await AsyncMainActor.run {
            try self.modelStorage.saveModel(course)
        }
    }
    
    func deleteCourse(_ course: Course) async throws {
        return try await AsyncMainActor.run {
            try self.modelStorage.delete(course)
        }
    }
    
    func getModulesForCourse(id: UUID) async throws -> [CourseModule] {
        return try await AsyncMainActor.run {
            let descriptor = FetchDescriptor<CourseModule>(predicate: #Predicate { $0.courseID == id })
            return try self.modelStorage.fetch(descriptor)
        }
    }
    
    func verifyDownloadStates() async throws {
        try await AsyncMainActor.run {
            do {
                // Get all modules
                let descriptor = FetchDescriptor<CourseModule>()
                let modules = try self.modelStorage.fetch(descriptor)
                
                self.logger.info("Verifying download states for \(modules.count) modules")
                
                for module in modules {
                    // Verify downloaded modules
                    if module.downloadState == .downloaded {
                        if let localURL = module.localFileURL, self.fileManager.fileExists(atPath: localURL.path) {
                            // File exists, state is valid
                            self.logger.info("Verified downloaded module: \(module.id)")
                        } else {
                            // File missing, fix state
                            self.logger.warning("File missing for module \(module.id) marked as downloaded")
                            module.downloadState = .notDownloaded
                            module.downloadProgress = 0
                            module.localFileURL = nil
                            module.updatedAt = Date()
                            try self.modelStorage.saveModel(module)
                        }
                    }
                    
                    // Verify downloading/paused modules (these states shouldn't persist between app launches)
                    if module.downloadState == .downloading || module.downloadState == .paused {
                        self.logger.warning("Resetting lingering download state for module: \(module.id)")
                        module.downloadState = .notDownloaded
                        module.downloadProgress = 0
                        module.updatedAt = Date()
                        try self.modelStorage.saveModel(module)
                    }
                }
                
                self.logger.info("Finished verifying download states")
            } catch {
                self.logger.error("Error verifying download states: \(error.localizedDescription)")
            }
        }
    }
}
