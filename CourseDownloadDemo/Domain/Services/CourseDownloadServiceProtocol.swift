//
//  CourseDownloadServiceProtocol.swift
//  CourseDownloadDemo
//
//  Created by Kashif Hussain on 10/05/25.
//


import Foundation
import Combine
import OSLog

protocol CourseDownloadServiceProtocol {
    func downloadModule(_ module: CourseModule) async throws
    func pauseDownload(moduleID: UUID) async throws
    func resumeDownload(moduleID: UUID) async throws
    func cancelDownload(moduleID: UUID) async throws
    func deleteDownload(moduleID: UUID) async throws
    func downloadEntireCourse(_ course: Course) async throws
    func pauseAllCourseDownloads(_ course: Course) async throws
    func resumeAllCourseDownloads(_ course: Course) async throws
    func cancelAllCourseDownloads(_ course: Course) async throws
    func getModuleDownloadState(moduleID: UUID) -> AnyPublisher<DownloadState, Never>
    func getModuleProgress(moduleID: UUID) -> AnyPublisher<Double, Never>
    func getCourseDownloadProgress(courseID: UUID) -> AnyPublisher<Double, Never>
}
