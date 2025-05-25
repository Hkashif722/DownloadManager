//
//  ModelStorageProtocol.swift
//  CourseDownloadDemo
//
//  Created by Kashif Hussain on 10/05/25.
//


// PersistenceManager/ModelStorageProtocol.swift
// PersistenceManager/ModelStorageProtocol.swift
import Foundation
import SwiftData

protocol ModelStorageProtocol {
    func saveDownloadState(id: UUID, state: DownloadState, progress: Double, localURL: URL?)
    func getDownloadState(id: UUID) -> (state: DownloadState, progress: Double, localURL: URL?)?
    func deleteDownloadState(id: UUID) // ADD THIS LINE
    func saveModel<T: PersistentModel>(_ model: T) throws
    func delete<T: PersistentModel>(_ model: T) throws
    func fetch<T: PersistentModel>(_ descriptor: FetchDescriptor<T>) throws -> [T]
    func getModelContext() -> ModelContext?
}
