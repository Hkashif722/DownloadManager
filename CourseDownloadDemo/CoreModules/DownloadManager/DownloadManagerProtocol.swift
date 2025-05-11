//
//  DownloadManagerProtocol.swift
//  CourseDownloadDemo
//
//  Created by Kashif Hussain on 10/05/25.
//


// DownloadManager/DownloadManagerProtocol.swift
import Foundation
import Combine

protocol DownloadManagerProtocol {
    var downloadProgress: AnyPublisher<(UUID, Double), Never> { get }
    var downloadStateChange: AnyPublisher<(UUID, DownloadState), Never> { get }
    
    func startDownload(id: UUID, url: URL, fileName: String, fileType: String) async throws
    func pauseDownload(id: UUID) async throws
    func resumeDownload(id: UUID) async throws
    func cancelDownload(id: UUID) async throws
    func deleteDownload(id: UUID) async throws
    func isDownloading(id: UUID) -> Bool
    func getActiveDownloads() async -> [UUID]
}
