import SwiftUI

struct CourseListView: View {
    @StateObject var viewModel: CourseListViewModel
    
    var body: some View {
        NavigationView {
            Group {
                if viewModel.isLoading {
                    ProgressView("Loading courses...")
                } else {
                    List {
                        ForEach(viewModel.courses) { course in
                            NavigationLink(destination: CourseDetailView(
                                viewModel: CourseDetailViewModel(
                                    course: course,
                                    courseDownloadService: DIContainer.shared.courseDownloadService
                                )
                            )) {
                                Text(course.title)
                                    .font(.headline)
                            }
                        }
                    }
                    .listStyle(InsetGroupedListStyle())
                }
            }
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
            .onAppear {
                viewModel.loadCourses()
                viewModel.verifyDownloadStates()
            }
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
}
