//
//  NetworkClientProtocol.swift
//  CourseDownloadDemo
//
//  Created by Kashif Hussain on 10/05/25.
//


// NetworkClient/NetworkClientProtocol.swift
import Foundation
import Combine

protocol NetworkClientProtocol {
    func download(url: URL) async throws -> (URL, URLResponse)
    func downloadWithProgress(url: URL) -> (task: URLSessionDownloadTask, progress: Progress)
    func configureBGSessionWithDelegate(_ delegate: URLSessionDownloadDelegate)
    func getAllTasks() async -> [URLSessionTask]
}
