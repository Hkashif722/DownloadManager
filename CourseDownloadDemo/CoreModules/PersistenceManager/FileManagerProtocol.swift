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


// PersistenceManager/FileManager+Extension.swift
import Foundation

extension FileManager: FileManagerProtocol {
    func getDownloadsDirectory() -> URL {
        let documentsDirectory = urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsDirectory.appendingPathComponent("Downloads")
    }
    
    func getUniqueFileName(originalName: String, inDirectory directory: URL) -> String {
        var fileName = originalName
        var counter = 1
        
        let fileURL = directory.appendingPathComponent(fileName)
        while fileExists(atPath: fileURL.path) {
            // Extract name and extension
            let nameWithoutExtension = (fileName as NSString).deletingPathExtension
            let fileExtension = (fileName as NSString).pathExtension
            
            // Create a new name with counter
            if counter == 1 {
                fileName = "\(nameWithoutExtension) (1).\(fileExtension)"
            }else {
                // Replace the last counter with the new one
                let regex = try! NSRegularExpression(pattern: " \\(\\d+\\)$")
                let range = NSRange(location: 0, length: nameWithoutExtension.count)
                let newName = regex.stringByReplacingMatches(
                    in: nameWithoutExtension,
                    options: [],
                    range: range,
                    withTemplate: " (\(counter))"
                )
                fileName = "\(newName).\(fileExtension)"  // Changed from 'extension' to 'fileExtension'
            }
            counter += 1
        }
        
        return fileName
    }
    
    func getFileSize(at url: URL) -> Int64? {
        do {
            let attributes = try attributesOfItem(atPath: url.path)
            return attributes[.size] as? Int64
        } catch {
            return nil
        }
    }
}
