// MARK: - Dependency Injection

// Presentation/DIContainer.swift
import Foundation
import OSLog

final class DIContainer {
    static let shared = DIContainer()
    
    private init() {
        // Initialize dependencies
        setupDependencies()
    }
    
    // Core dependencies
    lazy var networkClient: NetworkClientProtocol = {
        let client = NetworkClient(backgroundIdentifier: "com.app.CourseDownloader.background")
        client.configureBGSessionWithHandler { [weak self] in
            self?.backgroundCompletionHandler?()
        }
        return client
    }()
    
    lazy var fileManager: FileManagerProtocol = FileManager.default
    
    lazy var modelStorage: ModelStorageProtocol = {
        return ModelStorage()
    }()
    
    lazy var downloadManager: DownloadManagerProtocol = {
        return DownloadManager(
            networkClient: networkClient,
            fileManager: fileManager,
            logger: Logger(subsystem: "com.app.CourseDownloader", category: "DownloadManager")
        )
    }()
    
    lazy var progressTracker: ProgressTrackerProtocol = {
        return ProgressTracker()
    }()
    
    lazy var errorHandler: ErrorHandlerProtocol = {
        return ErrorHandler()
    }()
    
    // Domain services
    lazy var courseRepository: CourseRepositoryProtocol = {
        return CourseRepository(
            modelStorage: modelStorage,
            fileManager: fileManager
        )
    }()
    
    lazy var courseDownloadService: CourseDownloadServiceProtocol = {
        return CourseDownloadService(
            downloadManager: downloadManager,
            modelStorage: modelStorage,
            fileManager: fileManager,
            progressTracker: progressTracker,
            errorHandler: errorHandler
        )
    }()
    
    // ViewModels factory
    func makeCourseListViewModel() -> CourseListViewModel {
        return CourseListViewModel(
            courseRepository: courseRepository,
            courseDownloadService: courseDownloadService
        )
    }
    
    // Background completion handler for app delegate
    var backgroundCompletionHandler: (() -> Void)?
    
    private func setupDependencies() {
        // Any additional setup can go here
    }
}
