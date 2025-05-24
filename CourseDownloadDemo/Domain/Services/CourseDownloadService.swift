//
//  CourseDownloadServiceProtocol.swift
//  CourseDownloadDemo
//
//  Created by Kashif Hussain on 10/05/25.
//


// Domain/Services/CourseDownloadService.swift
// CourseDownloadService.swift
// Domain/Services/CourseDownloadService.swift
import Foundation
import Combine
import OSLog

final class CourseDownloadService: CourseDownloadServiceProtocol {
    private let downloadManager: DownloadManagerProtocol
    private let modelStorage: ModelStorageProtocol
    private let fileManager: FileManagerProtocol
    private let progressTracker: ProgressTrackerProtocol
    private let errorHandler: ErrorHandlerProtocol
    private let logger: Logger
    
    private var statePublishers: [UUID: CurrentValueSubject<DownloadState, Never>] = [:]
    private var progressPublishers: [UUID: CurrentValueSubject<Double, Never>] = [:]
    private var courseProgressPublishers: [UUID: CurrentValueSubject<Double, Never>] = [:]
    
    private var cancellables = Set<AnyCancellable>()
    
    init(
        downloadManager: DownloadManagerProtocol,
        modelStorage: ModelStorageProtocol,
        fileManager: FileManagerProtocol,
        progressTracker: ProgressTrackerProtocol,
        errorHandler: ErrorHandlerProtocol,
        logger: Logger = Logger(subsystem: "com.app.CourseDownloader", category: "CourseDownloadService")
    ) {
        self.downloadManager = downloadManager
        self.modelStorage = modelStorage
        self.fileManager = fileManager
        self.progressTracker = progressTracker
        self.errorHandler = errorHandler
        self.logger = logger
        
        setupSubscriptions()
    }
    
    private func setupSubscriptions() {
        // Subscribe to download state changes
        downloadManager.downloadStateChange
            .sink { [weak self] id, state in
                self?.handleStateChange(id: id, state: state)
            }
            .store(in: &cancellables)
        
        // Subscribe to download progress updates
        downloadManager.downloadProgress
            .sink { [weak self] id, progress in
                self?.handleProgressUpdate(id: id, progress: progress)
            }
            .store(in: &cancellables)
            
        // Subscribe to error handling
        errorHandler.errors
            .sink { [weak self] error in
                self?.logger.error("Error occurred: \(error)")
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Download state and progress management
    
    private func handleStateChange(id: UUID, state: DownloadState) {
        // Update persistence
        let savedState = modelStorage.getDownloadState(id: id)
        let localURL: URL? = state == .downloaded ? savedState?.localURL : nil
        
        modelStorage.saveDownloadState(
            id: id,
            state: state,
            progress: savedState?.progress ?? 0.0,
            localURL: localURL
        )
        
        // Update publisher if exists
        statePublishers[id]?.send(state)
        
        // Log state changes
        logger.info("Module \(id.uuidString) state changed to: \(state.rawValue)")
    }
    
    private func handleProgressUpdate(id: UUID, progress: Double) {
        // Update persistence
        if let savedState = modelStorage.getDownloadState(id: id) {
            modelStorage.saveDownloadState(
                id: id,
                state: savedState.state,
                progress: progress,
                localURL: savedState.localURL
            )
        }
        
        // Update publisher if exists
        progressPublishers[id]?.send(progress)
        
        // Update progress tracker
        progressTracker.updateProgress(id: id, progress: progress)
    }
    
    // MARK: - Public API
    
    func downloadModule(_ module: CourseModule) async throws {
        // Track this download
        progressTracker.trackDownload(id: module.id, groupID: module.courseID)
        
        // Get file extension from URL
        let fileExtension = module.fileURL.pathExtension.isEmpty ? "mp4" : module.fileURL.pathExtension
        
        // Start download
        do {
            try await downloadManager.startDownload(
                id: module.id,
                url: module.fileURL,
                fileName: module.title,
                fileType: fileExtension
            )
            logger.info("Started download for module: \(module.title)")
        } catch {
            logger.error("Failed to start download for module \(module.id): \(error)")
            errorHandler.handle(error)
            throw error
        }
    }
    
    func pauseDownload(moduleID: UUID) async throws {
        do {
            try await downloadManager.pauseDownload(id: moduleID)
            logger.info("Paused download for module: \(moduleID)")
        } catch {
            logger.error("Failed to pause download: \(error)")
            errorHandler.handle(error)
            throw error
        }
    }
    
    func resumeDownload(moduleID: UUID) async throws {
        do {
            try await downloadManager.resumeDownload(id: moduleID)
            logger.info("Resumed download for module: \(moduleID)")
        } catch {
            logger.error("Failed to resume download: \(error)")
            errorHandler.handle(error)
            throw error
        }
    }
    
    func cancelDownload(moduleID: UUID) async throws {
        do {
            try await downloadManager.cancelDownload(id: moduleID)
            logger.info("Cancelled download for module: \(moduleID)")
        } catch {
            logger.error("Failed to cancel download: \(error)")
            errorHandler.handle(error)
            throw error
        }
    }
    
    func deleteDownload(moduleID: UUID) async throws {
        do {
            try await downloadManager.deleteDownload(id: moduleID)
            logger.info("Deleted download for module: \(moduleID)")
        } catch {
            logger.error("Failed to delete download: \(error)")
            errorHandler.handle(error)
            throw error
        }
    }
    
    func downloadEntireCourse(_ course: Course) async throws {
        logger.info("Starting download for entire course: \(course.title)")
        var failedModules: [CourseModule] = []
        
        for module in course.modules {
            do {
                try await downloadModule(module)
            } catch {
                failedModules.append(module)
                logger.error("Failed to download module \(module.title): \(error)")
            }
        }
        
        if !failedModules.isEmpty {
            let error = NSError(
                domain: "CourseDownloadService",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Failed to download \(failedModules.count) modules"]
            )
            errorHandler.handle(error)
            throw error
        }
    }
    
    func pauseAllCourseDownloads(_ course: Course) async throws {
        for module in course.modules {
            if downloadManager.isDownloading(id: module.id) {
                do {
                    try await pauseDownload(moduleID: module.id)
                } catch {
                    logger.error("Failed to pause module \(module.id): \(error)")
                }
            }
        }
    }
    
    func resumeAllCourseDownloads(_ course: Course) async throws {
        for module in course.modules {
            if let state = modelStorage.getDownloadState(id: module.id)?.state, state == .paused {
                do {
                    try await resumeDownload(moduleID: module.id)
                } catch {
                    logger.error("Failed to resume module \(module.id): \(error)")
                }
            }
        }
    }
    
    func cancelAllCourseDownloads(_ course: Course) async throws {
        for module in course.modules {
            if downloadManager.isDownloading(id: module.id) {
                do {
                    try await cancelDownload(moduleID: module.id)
                } catch {
                    logger.error("Failed to cancel module \(module.id): \(error)")
                }
            }
        }
    }
    
    func getModuleDownloadState(moduleID: UUID) -> AnyPublisher<DownloadState, Never> {
        if let publisher = statePublishers[moduleID] {
            return publisher.eraseToAnyPublisher()
        }
        
        // Create new publisher with initial value from storage
        let initialState = modelStorage.getDownloadState(id: moduleID)?.state ?? .notDownloaded
        let publisher = CurrentValueSubject<DownloadState, Never>(initialState)
        statePublishers[moduleID] = publisher
        
        return publisher.eraseToAnyPublisher()
    }
    
    func getModuleProgress(moduleID: UUID) -> AnyPublisher<Double, Never> {
        if let publisher = progressPublishers[moduleID] {
            return publisher.eraseToAnyPublisher()
        }
        
        // Create new publisher with initial value from storage
        let initialProgress = modelStorage.getDownloadState(id: moduleID)?.progress ?? 0.0
        let publisher = CurrentValueSubject<Double, Never>(initialProgress)
        progressPublishers[moduleID] = publisher
        
        return publisher.eraseToAnyPublisher()
    }
    
    func getCourseDownloadProgress(courseID: UUID) -> AnyPublisher<Double, Never> {
        if let publisher = courseProgressPublishers[courseID] {
            return publisher.eraseToAnyPublisher()
        }
        
        // Create new publisher
        let publisher = CurrentValueSubject<Double, Never>(0.0)
        courseProgressPublishers[courseID] = publisher
        
        // Subscribe to aggregate progress for this course
        progressTracker.aggregateProgress
            .filter { id, _ in id == courseID }
            .map { _, progress in progress }
            .sink { [weak publisher] progress in
                publisher?.send(progress)
            }
            .store(in: &cancellables)
        
        return publisher.eraseToAnyPublisher()
    }
}
