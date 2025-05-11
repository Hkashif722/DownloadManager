// NetworkClient/NetworkClientProtocol.swift
import Foundation
import Combine

protocol NetworkClientProtocol {
    func download(url: URL, toFile destinationURL: URL) async throws
    func downloadWithProgress(url: URL) -> (task: URLSessionDownloadTask, progress: Progress)
    func configureBGSessionWithHandler(_ completionHandler: @escaping () -> Void)
    func getAllTasks() async -> [URLSessionTask]
}
