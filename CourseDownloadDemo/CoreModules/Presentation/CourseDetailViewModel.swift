//
//  CourseDetailViewModel.swift
//  CourseDownloadDemo
//
//  Created by Kashif Hussain on 10/05/25.
//


// Presentation/ViewModels/CourseDetailViewModel.swift
import Foundation
import Combine
import SwiftUI
import OSLog

@MainActor
final class CourseDetailViewModel: ObservableObject {
    @Published var course: Course
    @Published var overallProgress: Double = 0
    @Published var isDownloadingAny: Bool = false
    @Published var moduleStates: [UUID: DownloadState] = [:]
    @Published var moduleProgress: [UUID: Double] = [:]
    @Published var errorMessage: String?
    
    private let courseDownloadService: CourseDownloadServiceProtocol
    private let logger: Logger
    private var cancellables = Set<AnyCancellable>()
    
    init(
        course: Course,
        courseDownloadService: CourseDownloadServiceProtocol,
        logger: Logger = Logger(subsystem: "com.app.CourseDownloader", category: "CourseDetailViewModel")
    ) {
        self.course = course
        self.courseDownloadService = courseDownloadService
        self.logger = logger
        
        setupSubscriptions()
        updateInitialState()
        refreshAllModuleStates() // NEW: Ensure states are refreshed from persistence
    }
    
    private func setupSubscriptions() {
        // Subscribe to course download progress
        courseDownloadService.getCourseDownloadProgress(courseID: course.id)
            .receive(on: RunLoop.main)
            .sink { [weak self] progress in
                self?.overallProgress = progress
            }
            .store(in: &cancellables)
        
        // Set up subscriptions for each module
        for module in course.modules {
            // Subscribe to module download state
            courseDownloadService.getModuleDownloadState(moduleID: module.id)
                .receive(on: RunLoop.main)
                .sink { [weak self] state in
                    self?.moduleStates[module.id] = state
                    self?.updateDownloadingStatus()
                }
                .store(in: &cancellables)
            
            // Subscribe to module progress
            courseDownloadService.getModuleProgress(moduleID: module.id)
                .receive(on: RunLoop.main)
                .sink { [weak self] progress in
                    self?.moduleProgress[module.id] = progress
                }
                .store(in: &cancellables)
        }
    }
    
    private func updateInitialState() {
        // Initialize module states and progress from current values
        for module in course.modules {
            moduleStates[module.id] = module.downloadState
            moduleProgress[module.id] = module.downloadProgress
        }
        
        updateDownloadingStatus()
    }
    
    // NEW: Method to refresh all module states from persistence
    private func refreshAllModuleStates() {
        for module in course.modules {
            // Cast to concrete type to access the refresh method
            if let downloadService = courseDownloadService as? CourseDownloadService {
                downloadService.refreshModuleState(moduleID: module.id)
            }
        }
    }
    
    private func updateDownloadingStatus() {
        isDownloadingAny = course.modules.contains { moduleStates[$0.id] == .downloading }
    }
    
    private func handleError(_ error: Error, context: String) {
        logger.error("\(context): \(error.localizedDescription)")
        errorMessage = "\(context): \(error.localizedDescription)"
    }
    
    func downloadAllModules() {
        errorMessage = nil
        Task {
            do {
                try await courseDownloadService.downloadEntireCourse(course)
                logger.info("Started downloading all modules for course: \(self.course.title)")
            } catch {
                handleError(error, context: "Failed to download course")
            }
        }
    }
    
    func cancelAllDownloads() {
        errorMessage = nil
        Task {
            do {
                try await courseDownloadService.cancelAllCourseDownloads(course)
                logger.info("Cancelled all downloads for course: \(self.course.title)")
            } catch {
                handleError(error, context: "Failed to cancel downloads")
            }
        }
    }
    
    func downloadModule(_ module: CourseModule) {
        errorMessage = nil
        Task {
            do {
                try await courseDownloadService.downloadModule(module)
                logger.info("Started downloading module: \(module.title)")
            } catch {
                handleError(error, context: "Failed to download module")
            }
        }
    }
    
    func pauseDownload(moduleID: UUID) {
        errorMessage = nil
        Task {
            do {
                try await courseDownloadService.pauseDownload(moduleID: moduleID)
                logger.info("Paused download for module: \(moduleID)")
            } catch {
                handleError(error, context: "Failed to pause download")
            }
        }
    }
    
    func resumeDownload(moduleID: UUID) {
        errorMessage = nil
        Task {
            do {
                try await courseDownloadService.resumeDownload(moduleID: moduleID)
                logger.info("Resumed download for module: \(moduleID)")
            } catch {
                handleError(error, context: "Failed to resume download")
            }
        }
    }
    
    func cancelDownload(moduleID: UUID) {
        errorMessage = nil
        Task {
            do {
                try await courseDownloadService.cancelDownload(moduleID: moduleID)
                logger.info("Cancelled download for module: \(moduleID)")
            } catch {
                handleError(error, context: "Failed to cancel download")
            }
        }
    }
    
    func deleteDownload(moduleID: UUID) {
            errorMessage = nil
            Task {
                do {
                    try await courseDownloadService.deleteDownload(moduleID: moduleID)
                    logger.info("Deleted download for module: \(moduleID)")
                    
                    // Force update the UI state
                    await MainActor.run {
                        self.moduleStates[moduleID] = .notDownloaded
                        self.moduleProgress[moduleID] = 0.0
                        
                        // Update the module object directly
                        if let module = self.course.modules.first(where: { $0.id == moduleID }) {
                            module.downloadState = .notDownloaded
                            module.downloadProgress = 0.0
                            module.localFileURL = nil
                        }
                        
                        // Force a view update
                        self.objectWillChange.send()
                    }
                    
                    // Refresh the state to ensure UI updates
                    if let downloadService = courseDownloadService as? CourseDownloadService {
                        downloadService.refreshModuleState(moduleID: moduleID)
                    }
                } catch {
                    handleError(error, context: "Failed to delete download")
                }
            }
        }
}
