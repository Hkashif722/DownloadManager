//
//  ModuleActionButton.swift
//  CourseDownloadDemo
//
//  Created by Kashif Hussain on 10/05/25.
//


// Presentation/Views/ModuleActionButton.swift
import SwiftUI

struct ModuleActionButton: View {
    let state: DownloadState
    let progress: Double
    @Binding var isPerformingAction: Bool
    let onAction: () -> Void
    
    var body: some View {
        ZStack {
            // Progress circle (only visible when downloading)
            if state == .downloading {
                Circle()
                    .stroke(
                        Color.blue.opacity(0.3),
                        lineWidth: 3
                    )
                    .frame(width: 36, height: 36)
                
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        Color.blue,
                        style: StrokeStyle(
                            lineWidth: 3,
                            lineCap: .round
                        )
                    )
                    .rotationEffect(.degrees(-90))
                    .frame(width: 36, height: 36)
            }
            
            // Button based on current state
            Button(action: onAction) {
                buttonImage
                    .font(.system(size: 18))
                    .frame(width: 36, height: 36)
            }
            .disabled(isPerformingAction)
        }
    }
    
    private var buttonImage: some View {
        Group {
            switch state {
            case .notDownloaded:
                Image(systemName: "arrow.down.circle.fill")
                    .foregroundColor(.blue)
                
            case .downloading:
                Image(systemName: "pause.fill")
                    .foregroundColor(.orange)
                
            case .paused:
                Image(systemName: "play.fill")
                    .foregroundColor(.green)
                
            case .downloaded:
                Image(systemName: "trash.fill")
                    .foregroundColor(.red)
                
            case .failed:
                Image(systemName: "arrow.clockwise")
                    .foregroundColor(.blue)
            }
        }
    }
}