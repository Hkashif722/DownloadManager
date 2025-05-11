//
//  ModuleRowView.swift
//  CourseDownloadDemo
//
//  Created by Kashif Hussain on 10/05/25.
//


// Presentation/Views/ModuleRowView.swift
import SwiftUI

struct ModuleRowView: View {
    let module: CourseModule
    let state: DownloadState
    let progress: Double
    let onDownload: () -> Void
    let onPause: () -> Void
    let onResume: () -> Void
    let onCancel: () -> Void
    let onDelete: () -> Void
    
    @State private var isPerformingAction: Bool = false
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                moduleIcon
                    .frame(width: 24, height: 24)
                
                Text(module.title)
                    .font(.body)
                
                Spacer()
                
                ModuleActionButton(
                    state: state,
                    progress: progress,
                    isPerformingAction: $isPerformingAction,
                    onAction: handleAction
                )
                .id(state) // Force view update when state changes
            }
            
            if state == .downloading || state == .paused {
                VStack(alignment: .leading) {
                    HStack {
                        Text(state == .downloading ? "Downloading:" : "Paused:")
                            .font(.caption)
                        
                        Text("\(Int(progress * 100))%")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    ProgressView(value: progress)
                        .progressViewStyle(LinearProgressViewStyle())
                }
                .padding(.top, 4)
            }
        }
        .padding(.vertical, 4)
    }
    
    private var moduleIcon: some View {
        Group {
            switch module.type {
            case .video:
                Image(systemName: "film")
                    .foregroundColor(.blue)
            case .pdf:
                Image(systemName: "doc.text")
                    .foregroundColor(.red)
            case .audio:
                Image(systemName: "waveform")
                    .foregroundColor(.purple)
            case .document:
                Image(systemName: "doc")
                    .foregroundColor(.green)
            }
        }
    }
    
    private func handleAction() {
        isPerformingAction = true
        
        switch state {
        case .notDownloaded, .failed:
            onDownload()
        case .downloading:
            onPause()
        case .paused:
            onResume()
        case .downloaded:
            onDelete()
        }
        
        // Re-enable button after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isPerformingAction = false
        }
    }
}
