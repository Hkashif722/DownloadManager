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
    
    func startDownload(id: UUID, url: URL, fileName: String, fileType: String) async
    func pauseDownload(id: UUID) async
    func resumeDownload(id: UUID) async
    func cancelDownload(id: UUID) async
    func deleteDownload(id: UUID) async
    func isDownloading(id: UUID) -> Bool
    func getActiveDownloads() async -> [UUID]
    func handleDownloadCompletion(id: UUID, tempURL: URL) async
    func handleDownloadFailure(id: UUID, error: Error?)
}
