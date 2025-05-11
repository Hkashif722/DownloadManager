// ProgressTracker/ProgressTrackerProtocol.swift
import Foundation
import Combine

protocol ProgressTrackerProtocol {
    var individualProgress: AnyPublisher<(UUID, Double), Never> { get }
    var aggregateProgress: AnyPublisher<(UUID, Double), Never> { get }
    
    func trackDownload(id: UUID, groupID: UUID?)
    func updateProgress(id: UUID, progress: Double)
    func calculateAggregateProgress(for groupID: UUID)
}
