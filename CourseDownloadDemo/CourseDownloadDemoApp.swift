//
//  CourseDownloadDemoApp.swift
//  CourseDownloadDemo
//
//  Created by Kashif Hussain on 10/05/25.
//

import SwiftUI
import OSLog

@main
struct CourseDownloadDemoApp: App {
    // Keep reference to DI container
    let container = DIContainer.shared
    
    var body: some Scene {
        WindowGroup {
            CourseListView(viewModel: DIContainer.shared.makeCourseListViewModel())
        }
    }
    
    init() {
        // Setup for background downloads
        setupBackgroundTasks()
    }
    
    private func setupBackgroundTasks() {
        #if os(iOS)
        // Handle background download completion
        let logger = Logger(subsystem: "com.app.CourseDownloader", category: "AppDelegate")
        
        // This would typically be in AppDelegate
        func application(_ application: UIApplication, handleEventsForBackgroundURLSession identifier: String, completionHandler: @escaping () -> Void) {
            logger.info("Handling background URL session: \(identifier)")
            DIContainer.shared.backgroundCompletionHandler = completionHandler
        }
        #endif
    }
}
