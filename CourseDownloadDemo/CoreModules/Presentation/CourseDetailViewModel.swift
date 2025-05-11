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
            await courseDownloadService.downloadEntireCourse(course)
        }
    }
    
    func cancelAllDownloads() {
        Task {
            await courseDownloadService.cancelAllCourseDownloads(course)
        }
    }
    
    func downloadModule(_ module: CourseModule) {
        Task {
            await courseDownloadService.downloadModule(module)
        }
    }
    
    func pauseDownload(moduleID: UUID) {
        Task {
            await courseDownloadService.pauseDownload(moduleID: moduleID)
        }
    }
    
    func resumeDownload(moduleID: UUID) {
        Task {
            await courseDownloadService.resumeDownload(moduleID: moduleID)
        }
    }
    
    func cancelDownload(moduleID: UUID) {
        Task {
            await courseDownloadService.cancelDownload(moduleID: moduleID)
        }
    }
    
    func deleteDownload(moduleID: UUID) {
        Task {
            await courseDownloadService.deleteDownload(moduleID: moduleID)
        }
    }
}
