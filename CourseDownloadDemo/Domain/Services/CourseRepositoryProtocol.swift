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
    
    @MainActor
    func getAllCourses() async throws -> [Course] {
        let descriptor = FetchDescriptor<Course>(
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )
        return try modelStorage.fetch(descriptor)
    }
    
    @MainActor
    func getCourse(id: UUID) async throws -> Course? {
        let descriptor = FetchDescriptor<Course>(predicate: #Predicate { $0.id == id })
        return try modelStorage.fetch(descriptor).first
    }
    
    @MainActor
    func saveCourse(_ course: Course) async throws {
        try modelStorage.saveModel(course)
    }
    
    @MainActor
    func deleteCourse(_ course: Course) async throws {
        // Delete associated download files
        for module in course.modules {
            let directory = fileManager.getDownloadsDirectory().appendingPathComponent(module.id.uuidString)
            if fileManager.fileExists(atPath: directory.path) {
                try? fileManager.removeItem(at: directory)
            }
        }
        
        // Delete the course from storage
        try modelStorage.delete(course)
    }
    
    @MainActor
    func getModulesForCourse(id: UUID) async throws -> [CourseModule] {
        let descriptor = FetchDescriptor<CourseModule>(
            predicate: #Predicate { $0.courseID == id },
            sortBy: [SortDescriptor(\.createdAt)]
        )
        return try modelStorage.fetch(descriptor)
    }
    
    @MainActor
      func verifyDownloadStates() async throws {
          // Get all modules
          let descriptor = FetchDescriptor<CourseModule>()
          let modules = try modelStorage.fetch(descriptor)
          
          logger.info("Verifying download states for \(modules.count) modules")
          
          var fixedCount = 0
          
          for module in modules {
              var needsUpdate = false
              
              // Check persistent storage for download state
              if let storedState = modelStorage.getDownloadState(id: module.id) {
                  // Sync state from DownloadRecord
                  module.downloadState = storedState.state
                  module.downloadProgress = storedState.progress
                  module.localFileURL = storedState.localURL
                  
                  // Verify downloaded modules have their files
                  if storedState.state == .downloaded {
                      if let localURL = storedState.localURL,
                         fileManager.fileExists(atPath: localURL.path) {
                          // File exists, state is correct
                          logger.info("Verified downloaded module: \(module.id)")
                      } else {
                          // File missing, fix both records
                          logger.warning("File missing for module \(module.id) marked as downloaded")
                          module.downloadState = .notDownloaded
                          module.downloadProgress = 0
                          module.localFileURL = nil
                          
                          // Delete the invalid download record
                          modelStorage.deleteDownloadState(id: module.id)
                          fixedCount += 1
                      }
                  }
                  
                  // Reset downloading/paused states
                  if storedState.state == .downloading || storedState.state == .paused {
                      logger.warning("Resetting lingering download state for module: \(module.id)")
                      module.downloadState = .notDownloaded
                      module.downloadProgress = 0
                      
                      // Delete the invalid download record
                      modelStorage.deleteDownloadState(id: module.id)
                      fixedCount += 1
                  }
                  
                  needsUpdate = true
              } else {
                  // No download record exists, ensure module reflects this
                  if module.downloadState != .notDownloaded {
                      module.downloadState = .notDownloaded
                      module.downloadProgress = 0
                      module.localFileURL = nil
                      needsUpdate = true
                      fixedCount += 1
                  }
              }
              
              // Save updates if needed
              if needsUpdate {
                  module.updatedAt = Date()
                  try modelStorage.saveModel(module)
              }
          }
          
          logger.info("Finished verifying download states. Fixed \(fixedCount) inconsistencies.")
      }
}
