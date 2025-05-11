// ProgressTracker/ProgressTracker.swift
import Foundation
import Combine
import OSLog

final class ProgressTracker: ProgressTrackerProtocol {
    private struct ProgressEntry {
        let id: UUID
        var progress: Double
        var groupID: UUID?
    }
    
    private let logger: Logger
    private var progressEntries: [UUID: ProgressEntry] = [:]
    
    private let individualProgressSubject = PassthroughSubject<(UUID, Double), Never>()
    private let aggregateProgressSubject = PassthroughSubject<(UUID, Double), Never>()
    
    var individualProgress: AnyPublisher<(UUID, Double), Never> {
        individualProgressSubject.eraseToAnyPublisher()
    }
    
    var aggregateProgress: AnyPublisher<(UUID, Double), Never> {
        aggregateProgressSubject.eraseToAnyPublisher()
    }
    
    init(logger: Logger = Logger(subsystem: "com.app.CourseDownloader", category: "ProgressTracker")) {
        self.logger = logger
    }
    
    func trackDownload(id: UUID, groupID: UUID? = nil) {
        progressEntries[id] = ProgressEntry(id: id, progress: 0.0, groupID: groupID)
        logger.info("Tracking progress for download \(id.uuidString)")
    }
    
    func updateProgress(id: UUID, progress: Double) {
        guard var entry = progressEntries[id] else {
            logger.warning("No progress entry found for \(id.uuidString)")
            return
        }
        
        entry.progress = progress
        progressEntries[id] = entry
        
        // Emit individual progress update
        individualProgressSubject.send((id, progress))
        
        // If this belongs to a group, update aggregate progress
        if let groupID = entry.groupID {
            calculateAggregateProgress(for: groupID)
        }
    }
    
    func calculateAggregateProgress(for groupID: UUID) {
        // Find all entries for this group
        let groupEntries = progressEntries.values.filter { $0.groupID == groupID }
        
        if groupEntries.isEmpty {
            logger.warning("No entries found for group \(groupID.uuidString)")
            return
        }
        
        // Calculate average progress
        let totalProgress = groupEntries.reduce(0.0) { $0 + $1.progress }
        let averageProgress = totalProgress / Double(groupEntries.count)
        
        // Emit aggregate progress update
        aggregateProgressSubject.send((groupID, averageProgress))
        logger.info("Aggregate progress for group \(groupID.uuidString): \(averageProgress)")
    }
}
