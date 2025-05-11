import Foundation
import Combine
import OSLog

protocol CourseDownloadServiceProtocol {
    func downloadModule(_ module: CourseModule) async
    func pauseDownload(moduleID: UUID) async
    func resumeDownload(moduleID: UUID) async
    func cancelDownload(moduleID: UUID) async
    func deleteDownload(moduleID: UUID) async
    func downloadEntireCourse(_ course: Course) async
    func pauseAllCourseDownloads(_ course: Course) async
    func resumeAllCourseDownloads(_ course: Course) async
    func cancelAllCourseDownloads(_ course: Course) async
    func getModuleDownloadState(moduleID: UUID) -> AnyPublisher<DownloadState, Never>
    func getModuleProgress(moduleID: UUID) -> AnyPublisher<Double, Never>
    func getCourseDownloadProgress(courseID: UUID) -> AnyPublisher<Double, Never>
}