// DIContainer.swift
// DIContainer.swift
import Foundation
import OSLog

final class DIContainer {
    static let shared = DIContainer()
    
    // Core dependencies
    lazy var networkClient: NetworkClientProtocol = {
        let client = NetworkClient(backgroundIdentifier: "com.app.CourseDownloader.background")
        return client
    }()
    
    lazy var fileManager: FileManagerProtocol = FileManager.default
    
    lazy var modelStorage: ModelStorageProtocol = {
        return ModelStorage()
    }()
    
    lazy var dataParser: DataParserProtocol = {
        return DataParser()
    }()
    
    lazy var progressTracker: ProgressTrackerProtocol = {
        return ProgressTracker()
    }()
    
    lazy var errorHandler: ErrorHandlerProtocol = {
        return ErrorHandler()
    }()
    
    lazy var downloadManager: DownloadManagerProtocol = {
        return DownloadManager(
            networkClient: networkClient,
            fileManager: fileManager,
            backgroundCompletionHandler: { [weak self] in
                self?.backgroundCompletionHandler?()
            }
        )
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
    @MainActor func makeCourseListViewModel() -> CourseListViewModel {
        return CourseListViewModel(
            courseRepository: courseRepository,
            courseDownloadService: courseDownloadService
        )
    }
    
    @MainActor func makeCourseDetailViewModel(course: Course) -> CourseDetailViewModel {
        return CourseDetailViewModel(
            course: course,
            courseDownloadService: courseDownloadService
        )
    }
    
    // Background completion handler for app delegate
    var backgroundCompletionHandler: (() -> Void)?
}
