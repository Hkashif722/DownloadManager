// Presentation/ViewModels/CourseListViewModel.swift
import Foundation
import Combine
import SwiftUI
import OSLog

@MainActor
final class CourseListViewModel: ObservableObject {
    @Published var courses: [Course] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let courseRepository: CourseRepositoryProtocol
    private let courseDownloadService: CourseDownloadServiceProtocol
    private let logger: Logger
    
    init(
        courseRepository: CourseRepositoryProtocol,
        courseDownloadService: CourseDownloadServiceProtocol,
        logger: Logger = Logger(subsystem: "com.app.CourseDownloader", category: "CourseListViewModel")
    ) {
        self.courseRepository = courseRepository
        self.courseDownloadService = courseDownloadService
        self.logger = logger
    }
    
    func loadCourses() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let loadedCourses = try await courseRepository.getAllCourses()
                await MainActor.run {
                    self.courses = loadedCourses
                    self.isLoading = false
                    self.logger.info("Loaded \(loadedCourses.count) courses")
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to load courses: \(error.localizedDescription)"
                    self.isLoading = false
                }
                logger.error("Failed to load courses: \(error.localizedDescription)")
            }
        }
    }
    
    func addSampleData() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                // Clear existing data first
                let existingCourses = try await courseRepository.getAllCourses()
                for course in existingCourses {
                    try await courseRepository.deleteCourse(course)
                }
                
                // Add sample courses
                let course1 = Course(
                    title: "SwiftUI Mastery",
                    description: "Learn advanced SwiftUI techniques"
                )
                
                let module1 = CourseModule(
                    title: "Introduction to SwiftUI",
                    type: .video,
                    fileURL: URL(string: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4")!,
                    fileSize: 5612595 // ~5.4 MB - actual size of this sample video
                )
                
                let module2 = CourseModule(
                    title: "SwiftUI Architecture",
                    type: .pdf,
                    fileURL: URL(string: "https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf")!,
                    fileSize: 13264 // ~13 KB - small test PDF
                )
                
                let module3 = CourseModule(
                    title: "SwiftUI Animations",
                    type: .video,
                    fileURL: URL(string: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4")!,
                    fileSize: 8134991 // ~7.8 MB
                )
                
                // Set up relationships
                course1.modules = [module1, module2, module3]
                for module in course1.modules {
                    module.course = course1
                    module.courseID = course1.id
                }
                
                try await courseRepository.saveCourse(course1)
                
                // Create another course
                let course2 = Course(
                    title: "Swift Concurrency",
                    description: "Master asynchronous Swift programming"
                )
                
                let module4 = CourseModule(
                    title: "Async/Await Fundamentals",
                    type: .video,
                    fileURL: URL(string: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerEscapes.mp4")!,
                    fileSize: 7615829 // ~7.3 MB
                )
                
                let module5 = CourseModule(
                    title: "Actor Model in Swift",
                    type: .pdf,
                    fileURL: URL(string: "https://www.africau.edu/images/default/sample.pdf")!,
                    fileSize: 3028 // ~3 KB
                )
                
                // Set up relationships
                course2.modules = [module4, module5]
                for module in course2.modules {
                    module.course = course2
                    module.courseID = course2.id
                }
                
                try await courseRepository.saveCourse(course2)
                
                logger.info("Sample data created successfully")
                
                // Reload courses
                await MainActor.run {
                    self.isLoading = false
                }
                loadCourses()
                
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to add sample data: \(error.localizedDescription)"
                    self.isLoading = false
                }
                logger.error("Failed to add sample data: \(error.localizedDescription)")
            }
        }
    }
    
    func verifyDownloadStates() {
        Task {
            do {
                try await courseRepository.verifyDownloadStates()
                logger.info("Successfully verified download states")
            } catch {
                logger.error("Failed to verify download states: \(error)")
                await MainActor.run {
                    self.errorMessage = "Failed to verify download states: \(error.localizedDescription)"
                }
            }
        }
    }
}
