import SwiftUI

// Main CourseListView
struct CourseListView: View {
    @StateObject var viewModel: CourseListViewModel
    
    var body: some View {
        NavigationView {
            CourseListContentView(viewModel: viewModel)
                .navigationTitle("Courses")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Add Sample Data") {
                            viewModel.addSampleData() 
                        }
                    }
                    
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Verify Downloads") {
                            viewModel.verifyDownloadStates()
                        }
                    }
                }
        }
        .errorAlert(errorMessage: viewModel.errorMessage) {
            viewModel.errorMessage = nil
        }
    }
}

// Content view handles conditional states
struct CourseListContentView: View {
    @ObservedObject var viewModel: CourseListViewModel
    
    var body: some View {
        Group {
            if viewModel.isLoading {
                LoadingView()
            } else if viewModel.courses.isEmpty {
                EmptyStateView(onAddSampleData: {
                    viewModel.addSampleData()
                })
            } else {
                CourseListContentRows(courses: viewModel.courses)
            }
        }
        .onAppear {
            viewModel.loadCourses()
            viewModel.verifyDownloadStates()
        }
    }
}

// Loading view
struct LoadingView: View {
    var body: some View {
        ProgressView("Loading courses...")
    }
}

// Empty state view
struct EmptyStateView: View {
    let onAddSampleData: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Text("No courses available")
                .font(.headline)
            
            Button("Add Sample Data") {
                onAddSampleData()
            }
            .buttonStyle(.borderedProminent)
        }
    }
}

// Course list rows
struct CourseListContentRows: View {
    let courses: [Course]
    
    var body: some View {
        List {
            ForEach(courses) { course in
                NavigationLink {
                    makeCourseDetailView(for: course)
                } label: {
                    Text(course.title)
                        .font(.headline)
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
    }
    
    private func makeCourseDetailView(for course: Course) -> some View {
        CourseDetailView(
            viewModel: CourseDetailViewModel(
                course: course,
                courseDownloadService: DIContainer.shared.courseDownloadService
            )
        )
    }
}

// Error alert extension
extension View {
    func errorAlert(errorMessage: String?, onDismiss: @escaping () -> Void) -> some View {
        let isPresented = Binding<Bool>(
            get: { errorMessage != nil },
            set: { if !$0 { onDismiss() } }
        )
        
        return alert(
            "Error",
            isPresented: isPresented,
            actions: {
                Button("OK") {
                    onDismiss()
                }
            },
            message: {
                if let message = errorMessage {
                    Text(message)
                }
            }
        )
    }
}
