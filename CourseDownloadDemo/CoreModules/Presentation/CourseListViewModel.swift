/ Presentation/ViewModels/CourseListViewModel.swift
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
    private var cancellables = Set<AnyCancellable>()
    
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
        
        Task {
            do {
                courses = try await courseRepository.getAllCourses()
                isLoading = false
            } catch {
                errorMessage = "Failed to load courses: \(error.localizedDescription)"
                isLoading = false
                logger.error("Failed to load courses: \(error.localizedDescription)")
            }
        }
    }
    
    func addSampleData() {
        // Clear existing data first
        Task {
            do {
                let existingCourses = try await courseRepository.getAllCourses()
                for course in existingCourses {
                    try await courseRepository.deleteCourse(course)
                }
                
                // Add sample courses
                let course1 = Course(title: "SwiftUI Mastery", description: "Learn advanced SwiftUI techniques")
                
                let module1 = CourseModule(
                    title: "Introduction to SwiftUI",
                    type: .video,
                    fileURL: URL(string: "https://example.com/video1.mp4")!,
                    fileSize: 104857600 // 100 MB
                )
                
                let module2 = CourseModule(
                    title: "SwiftUI Architecture",
                    type: .pdf,
                    fileURL: URL(string: "https://example.com/pdf1.pdf")!,
                    fileSize: 20971520 // 20 MB
                )
                
                let module3 = CourseModule(
                    title: "SwiftUI Animations",
                    type: .video,
                    fileURL: URL(string: "https://example.com/video2.mp4")!,
                    fileSize: 52428800 // 50 MB
                )
                
                course1.modules = [module1, module2, module3]
                module1.course = course1
                module1.courseID = course1.id
                module2.course = course1
                module2.courseID = course1.id
                module3.course = course1
                module3.courseID = course1.id
                
                try await courseRepository.saveCourse(course1)
                
                // Create another course
                let course2 = Course(title: "Swift Concurrency", description: "Master asynchronous Swift programming")
                
                let module4 = CourseModule(
                    title: "Async/Await Fundamentals",
                    type: .video,
                    fileURL: URL(string: "https://example.com/video3.mp4")!,
                    fileSize: 78643200 // 75 MB
                )
                
                let module5 = CourseModule(
                    title: "Actor Model in Swift",
                    type: .document,
                    fileURL: URL(string: "https://example.com/doc1.docx")!,
                    fileSize: 5242880 // 5 MB
                )
                
                course2.modules = [module4, module5]
                module4.course = course2
                module4.courseID = course2.id
                module5.course = course2
                module5.courseID = course2.id
                
                try await courseRepository.saveCourse(course2)
                
                logger.info("Sample data created successfully")
                
                // Reload courses
                loadCourses()
            } catch {
                errorMessage = "Failed to add sample data: \(error.localizedDescription)"
                logger.error("Failed to add sample data: \(error.localizedDescription)")
            }
        }
    }
    
    func verifyDownloadStates() {
        Task {
            await courseRepository.verifyDownloadStates()
        }
    }
}
