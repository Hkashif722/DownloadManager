//
//  DownloadTaskInfo.swift
//  CourseDownloadDemo
//
//  Created by Kashif Hussain on 10/05/25.
//


// DownloadManager/DownloadTaskInfo.swift
import Foundation

struct DownloadTaskInfo: Identifiable {
    let id: UUID
    let task: URLSessionDownloadTask
    let progress: Progress
    let fileName: String
    let fileType: String
    var progressObserver: NSKeyValueObservation?
}