// PersistenceManager/ModelStorage.swift
import Foundation
import SwiftData
import OSLog

final class ModelStorage: ModelStorageProtocol {
    private var modelContainer: ModelContainer?
    private var modelContext: ModelContext?
    private let logger: Logger
    
    init(logger: Logger = Logger(subsystem: "com.app.CourseDownloader", category: "ModelStorage")) {
        self.logger = logger
        setupContainer()
    }
    
    private func setupContainer() {
        do {
            // Replace with actual model schema
            let schema = Schema([DownloadRecord.self])
            let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
            modelContext = modelContainer?.mainContext
            logger.info("Model container setup successfully")
        } catch {
            logger.error("Failed to create model container: \(error.localizedDescription)")
        }
    }
    
    func saveDownloadState(id: UUID, state: DownloadState, progress: Double, localURL: URL?) {
        guard let context = modelContext else {
            logger.warning("No model context available")
            return
        }
        
        do {
            // Check if record exists
            let descriptor = FetchDescriptor<DownloadRecord>(predicate: #Predicate { $0.id == id })
            let existingRecords = try context.fetch(descriptor)
            
            if let existingRecord = existingRecords.first {
                // Update existing record
                existingRecord.state = state.rawValue
                existingRecord.progress = progress
                existingRecord.localURL = localURL
            } else {
                // Create new record
                let record = DownloadRecord(
                    id: id,
                    state: state.rawValue,
                    progress: progress,
                    localURL: localURL
                )
                context.insert(record)
            }
            
            try context.save()
            logger.info("Saved download state for \(id.uuidString)")
        } catch {
            logger.error("Failed to save download state: \(error.localizedDescription)")
        }
    }
    
    func getDownloadState(id: UUID) -> (state: DownloadState, progress: Double, localURL: URL?)? {
        guard let context = modelContext else {
            logger.warning("No model context available")
            return nil
        }
        
        do {
            let descriptor = FetchDescriptor<DownloadRecord>(predicate: #Predicate { $0.id == id })
            let records = try context.fetch(descriptor)
            
            if let record = records.first,
               let state = DownloadState(rawValue: record.state) {
                return (state: state, progress: record.progress, localURL: record.localURL)
            }
        } catch {
            logger.error("Failed to fetch download state: \(error.localizedDescription)")
        }
        
        return nil
    }
    
    func saveModel<T: PersistentModel>(_ model: T) throws {
        guard let context = modelContext else {
            throw NSError(domain: "ModelStorage", code: 1, userInfo: [NSLocalizedDescriptionKey: "No model context available"])
        }
        
        context.insert(model)
        try context.save()
    }
    
    func delete<T: PersistentModel>(_ model: T) throws {
        guard let context = modelContext else {
            throw NSError(domain: "ModelStorage", code: 1, userInfo: [NSLocalizedDescriptionKey: "No model context available"])
        }
        
        context.delete(model)
        try context.save()
    }
    
    func fetch<T: PersistentModel>(_ descriptor: FetchDescriptor<T>) throws -> [T] {
        guard let context = modelContext else {
            throw NSError(domain: "ModelStorage", code: 1, userInfo: [NSLocalizedDescriptionKey: "No model context available"])
        }
        
        return try context.fetch(descriptor)
    }
    
    func getModelContext() -> ModelContext? {
        return modelContext
    }
}
