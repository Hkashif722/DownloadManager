@Model
final class CourseModule: Identifiable {
    @Attribute(.unique) var id: UUID
    var title: String
    var type: ModuleType
    var fileURL: URL
    var localFileURL: URL?
    var downloadState: DownloadState
    var downloadProgress: Double
    var fileSize: Int64
    var courseID: UUID?
    var course: Course?
    var createdAt: Date
    var updatedAt: Date
    
    init(id: UUID = UUID(), title: String, type: ModuleType, fileURL: URL, fileSize: Int64 = 0) {
        self.id = id
        self.title = title
        self.type = type
        self.fileURL = fileURL
        self.downloadState = .notDownloaded
        self.downloadProgress = 0.0
        self.fileSize = fileSize
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}