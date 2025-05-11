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
            let extension = (fileName as NSString).pathExtension
            
            // Create a new name with counter
            if counter == 1 {
                fileName = "\(nameWithoutExtension) (1).\(extension)"
            } else {
                // Replace the last counter with the new one
                let regex = try! NSRegularExpression(pattern: " \\(\\d+\\)$")
                let range = NSRange(location: 0, length: nameWithoutExtension.count)
                let newName = regex.stringByReplacingMatches(
                    in: nameWithoutExtension,
                    options: [],
                    range: range,
                    withTemplate: " (\(counter))"
                )
                fileName = "\(newName).\(extension)"
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