// DownloadManager/DownloadState.swift
import Foundation

enum DownloadState: String, Codable {
    case notDownloaded
    case downloading
    case paused
    case downloaded
    case failed
}