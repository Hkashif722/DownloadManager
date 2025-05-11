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
    
    private func updateDownloadingStatus() {
        isDownloadingAny = course.modules.contains { moduleStates[$0.id] == .downloading }
    }
    
    func downloadAllModules() {
        Task {
            do {
                try await courseDownloadService.downloadEntireCourse(course)
            } catch {
                
            }
        }
    }
    
    func cancelAllDownloads() {
        Task {
            do {
                try await courseDownloadService.cancelAllCourseDownloads(course)
            } catch {
                
            }
            
        }
    }
    
    func downloadModule(_ module: CourseModule) {
        Task {
            do {
                try await courseDownloadService.downloadModule(module)
            } catch {
                
            }
        }
    }
    
    func pauseDownload(moduleID: UUID) {
        Task {
            do {
                try await courseDownloadService.pauseDownload(moduleID: moduleID)
            } catch {
                
            }
        }
    }
    
    func resumeDownload(moduleID: UUID) {
        Task {
            do {
                try await courseDownloadService.resumeDownload(moduleID: moduleID)
            } catch {
                
            }
        }
    }
    
    func cancelDownload(moduleID: UUID) {
        Task {
            do {
                try await courseDownloadService.cancelDownload(moduleID: moduleID)
            } catch {
                
            }
           
        }
    }
    
    func deleteDownload(moduleID: UUID) {
        Task {
            do {
                try await  courseDownloadService.deleteDownload(moduleID: moduleID)
            } catch {
                
            }
        }
    }
}
