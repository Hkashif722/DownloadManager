// DIContainer.swift
// DIContainer.swift
// DIContainer.swift
import Foundation
import OSLog

final class DIContainer {
    static let shared = DIContainer()
    
    // Core dependencies - use private(set) to ensure thread safety
    private(set) lazy var networkClient: NetworkClientProtocol = {
        let client = NetworkClient(backgroundIdentifier: "com.app.CourseDownloader.background")
        return client
    }()
    
    private(set) lazy var fileManager: FileManagerProtocol = FileManager.default
    
    @MainActor
    private(set) lazy var modelStorage: ModelStorageProtocol = {
        return ModelStorage()
    }()
    
    private(set) lazy var dataParser: DataParserProtocol = {
        return DataParser()
    }()
    
    private(set) lazy var progressTracker: ProgressTrackerProtocol = {
        return ProgressTracker()
    }()
    
    private(set) lazy var errorHandler: ErrorHandlerProtocol = {
        return ErrorHandler()
    }()
    
    @MainActor
    private(set) lazy var downloadManager: DownloadManagerProtocol = {
        return DownloadManager(
            networkClient: networkClient,
            fileManager: fileManager,
            backgroundCompletionHandler: { [weak self] in
                DispatchQueue.main.async {
                    self?.backgroundCompletionHandler?()
                    self?.backgroundCompletionHandler = nil
                }
            }
        )
    }()
    
    // Domain services
    @MainActor
    private(set) lazy var courseRepository: CourseRepositoryProtocol = {
        return CourseRepository(
            modelStorage: modelStorage,
            fileManager: fileManager
        )
    }()
    
    @MainActor
    private(set) lazy var courseDownloadService: CourseDownloadServiceProtocol = {
        return CourseDownloadService(
            downloadManager: downloadManager,
            modelStorage: modelStorage,
            fileManager: fileManager,
            progressTracker: progressTracker,
            errorHandler: errorHandler
        )
    }()
    
    // ViewModels factory
    @MainActor
    func makeCourseListViewModel() -> CourseListViewModel {
        return CourseListViewModel(
            courseRepository: courseRepository,
            courseDownloadService: courseDownloadService
        )
    }
    
    @MainActor
    func makeCourseDetailViewModel(course: Course) -> CourseDetailViewModel {
        return CourseDetailViewModel(
            course: course,
            courseDownloadService: courseDownloadService
        )
    }
    
    // Background completion handler for app delegate
    var backgroundCompletionHandler: (() -> Void)?
    
    // Private initializer to enforce singleton
    private init() {}
}
