//
//  FileManagerProtocol.swift
//  CourseDownloadDemo
//
//  Created by Kashif Hussain on 10/05/25.
//


// PersistenceManager/FileManagerProtocol.swift
import Foundation

protocol FileManagerProtocol {
    func fileExists(atPath path: String) -> Bool
    func createDirectory(at url: URL, withIntermediateDirectories createIntermediates: Bool, attributes: [FileAttributeKey: Any]?) throws
    func removeItem(at url: URL) throws
    func copyItem(at srcURL: URL, to dstURL: URL) throws
    func moveItem(at srcURL: URL, to dstURL: URL) throws
    func getDownloadsDirectory() -> URL
    func getUniqueFileName(originalName: String, inDirectory directory: URL) -> String
    func getFileSize(at url: URL) -> Int64?
}