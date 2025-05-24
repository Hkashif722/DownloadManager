// PersistenceManager/FileManager+Extension.swift
import Foundation

extension FileManager: FileManagerProtocol {
    // temporaryDirectory is already provided by FileManager
    
    func getDownloadsDirectory() -> URL {
        let documentsDirectory = urls(for: .documentDirectory, in: .userDomainMask)[0]
        let downloadsDirectory = documentsDirectory.appendingPathComponent("Downloads")
        
        // Ensure downloads directory exists
        if !fileExists(atPath: downloadsDirectory.path) {
            try? createDirectory(at: downloadsDirectory, withIntermediateDirectories: true, attributes: nil)
        }
        
        return downloadsDirectory
    }
    
    func getUniqueFileName(originalName: String, inDirectory directory: URL) -> String {
        var fileName = originalName
        var counter = 1
        
        var fileURL = directory.appendingPathComponent(fileName)
        while fileExists(atPath: fileURL.path) {
            // Extract name and extension
            let nameWithoutExtension = (fileName as NSString).deletingPathExtension
            let fileExtension = (fileName as NSString).pathExtension
            
            // Create a new name with counter
            if counter == 1 {
                fileName = "\(nameWithoutExtension) (1)"
            } else {
                // Replace the last counter with the new one using regex
                if let regex = try? NSRegularExpression(pattern: " \\(\\d+\\)$", options: []) {
                    let range = NSRange(location: 0, length: nameWithoutExtension.count)
                    let newName = regex.stringByReplacingMatches(
                        in: nameWithoutExtension,
                        options: [],
                        range: range,
                        withTemplate: " (\(counter))"
                    )
                    fileName = newName
                } else {
                    fileName = "\(nameWithoutExtension) (\(counter))"
                }
            }
            
            // Add extension back if it exists
            if !fileExtension.isEmpty {
                fileName = "\(fileName).\(fileExtension)"
            }
            
            counter += 1
            fileURL = directory.appendingPathComponent(fileName)
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
