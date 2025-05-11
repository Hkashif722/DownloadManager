//
//  DataParserProtocol.swift
//  CourseDownloadDemo
//
//  Created by Kashif Hussain on 11/05/25.
//


// DataParserProtocol.swift
import Foundation

protocol DataParserProtocol {
    func parse<T: Decodable>(data: Data) throws -> T
    func parseJSON<T: Decodable>(data: Data) throws -> T
    func parseObject<T: Decodable>(json: [String: Any]) throws -> T
}

// DataParser.swift
import Foundation
import OSLog

final class DataParser: DataParserProtocol {
    private let jsonDecoder: JSONDecoder
    private let logger: Logger
    
    init(
        jsonDecoder: JSONDecoder = JSONDecoder(),
        logger: Logger = Logger(subsystem: "com.app.CourseDownloader", category: "DataParser")
    ) {
        self.jsonDecoder = jsonDecoder
        self.logger = logger
        
        // Configure decoder
        jsonDecoder.dateDecodingStrategy = .iso8601
        jsonDecoder.keyDecodingStrategy = .convertFromSnakeCase
    }
    
    func parse<T: Decodable>(data: Data) throws -> T {
        do {
            return try jsonDecoder.decode(T.self, from: data)
        } catch {
            logger.error("Failed to parse data: \(error.localizedDescription)")
            throw AppError.parsing(error.localizedDescription)
        }
    }
    
    func parseJSON<T: Decodable>(data: Data) throws -> T {
        do {
            return try jsonDecoder.decode(T.self, from: data)
        } catch {
            logger.error("Failed to parse JSON: \(error.localizedDescription)")
            throw AppError.parsing(error.localizedDescription)
        }
    }
    
    func parseObject<T: Decodable>(json: [String: Any]) throws -> T {
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: json, options: [])
            return try jsonDecoder.decode(T.self, from: jsonData)
        } catch {
            logger.error("Failed to parse object: \(error.localizedDescription)")
            throw AppError.parsing(error.localizedDescription)
        }
    }
}