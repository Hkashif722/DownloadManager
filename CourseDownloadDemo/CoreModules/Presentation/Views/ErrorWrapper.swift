/ Helper for alert binding
struct ErrorWrapper: Identifiable {
    let id = UUID()
    let message: String
    
    init(_ message: String) {
        self.message = message
    }
}

// Presentation/Views/CourseDetailView.swift
import SwiftUI

struct CourseDetailView: View {
    @ObservedObject var viewModel: CourseDetailViewModel
    
    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    Text(viewModel.course.title)
                        .font(.title)
                        .bold()
                    
                    Text(viewModel.course.descriptionText)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    if viewModel.isDownloadingAny {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Overall Progress: \(Int(viewModel.overallProgress * 100))%")
                                .font(.subheadline)
                            
                            ProgressView(value: viewModel.overallProgress)
                                .progressViewStyle(LinearProgressViewStyle())
                        }
                        .padding(.vertical, 8)
                    }
                    
                    Button(action: {
                        if viewModel.isDownloadingAny {
                            viewModel.cancelAllDownloads()
                        } else {
                            viewModel.downloadAllModules()
                        }
                    }) {
                        Text(viewModel.isDownloadingAny ? "Cancel All Downloads" : "Download All Modules")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(viewModel.isDownloadingAny ? Color.red : Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            .font(.headline)
                    }
                    .padding(.top, 8)
                }
                .padding(.vertical, 8)
            }
            
            Section(header: Text("MODULES").font(.headline)) {
                ForEach(viewModel.course.modules) { module in
                    ModuleRowView(
                        module: module,
                        state: viewModel.moduleStates[module.id] ?? .notDownloaded,
                        progress: viewModel.moduleProgress[module.id] ?? 0,
                        onDownload: { viewModel.downloadModule(module) },
                        onPause: { viewModel.pauseDownload(moduleID: module.id) },
                        onResume: { viewModel.resumeDownload(moduleID: module.id) },
                        onCancel: { viewModel.cancelDownload(moduleID: module.id) },
                        onDelete: { viewModel.deleteDownload(moduleID: module.id) }
                    )
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
        .navigationTitle("Course Details")
        .alert(item: Binding(
            get: { viewModel.errorMessage.map { ErrorWrapper($0) } },
            set: { viewModel.errorMessage = $0?.message }
        )) { error in
            Alert(
                title: Text("Error"),
                message: Text(error.message),
                dismissButton: .default(Text("OK"))
            )
        }
    }
}
