//
//  ModelStorage.swift
//  CourseDownloadDemo
//
//  Created by Kashif Hussain on 10/05/25.
//


// PersistenceManager/ModelStorage.swift
import Foundation
import SwiftData
import OSLog

@MainActor
final class ModelStorage: ModelStorageProtocol {
    private var modelContainer: ModelContainer?
    private var modelContext: ModelContext?
    private let logger: Logger
    private let setupSemaphore = DispatchSemaphore(value: 0)
    private var isSetupComplete = false
    
    init(logger: Logger = Logger(subsystem: "com.app.CourseDownloader", category: "ModelStorage")) {
        self.logger = logger
        setupContainer()
    }
    
    private func setupContainer() {
        do {
            let schema = Schema([
                Course.self,
                CourseModule.self,
                DownloadRecord.self
            ])
            
            let modelConfiguration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                allowsSave: true
            )
            
//            logger.info("Setting up SwiftData container with schema: \(schema)")
            modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
            modelContext = modelContainer?.mainContext
            isSetupComplete = true
            setupSemaphore.signal()
            
            logger.info("Model container setup successfully")
        } catch {
            logger.error("Failed to create model container: \(error.localizedDescription)")
            setupSemaphore.signal() // Signal even on error to prevent deadlock
        }
    }
    
    private func waitForSetup() {
        guard !isSetupComplete else { return }
        _ = setupSemaphore.wait(timeout: .now() + 5.0) // 5 second timeout
    }
    
    func saveDownloadState(id: UUID, state: DownloadState, progress: Double, localURL: URL?) {
        waitForSetup()
        
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
                existingRecord.updatedAt = Date()
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
        waitForSetup()
        
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
        waitForSetup()
        
        guard let context = modelContext else {
            throw NSError(domain: "ModelStorage", code: 1, userInfo: [NSLocalizedDescriptionKey: "No model context available"])
        }
        
        context.insert(model)
        try context.save()
    }
    
    func delete<T: PersistentModel>(_ model: T) throws {
        waitForSetup()
        
        guard let context = modelContext else {
            throw NSError(domain: "ModelStorage", code: 1, userInfo: [NSLocalizedDescriptionKey: "No model context available"])
        }
        
        context.delete(model)
        try context.save()
    }
    
    func fetch<T: PersistentModel>(_ descriptor: FetchDescriptor<T>) throws -> [T] {
        waitForSetup()
        
        guard let context = modelContext else {
            throw NSError(domain: "ModelStorage", code: 1, userInfo: [NSLocalizedDescriptionKey: "No model context available"])
        }
        
        return try context.fetch(descriptor)
    }
    
    func getModelContext() -> ModelContext? {
        waitForSetup()
        return modelContext
    }
}
