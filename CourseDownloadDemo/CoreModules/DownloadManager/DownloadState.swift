//
//  DownloadState.swift
//  CourseDownloadDemo
//
//  Created by Kashif Hussain on 10/05/25.
//


// DownloadManager/DownloadState.swift
import Foundation

enum DownloadState: String, Codable {
    case notDownloaded
    case downloading
    case paused
    case downloaded
    case failed
}