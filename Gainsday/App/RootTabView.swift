import SwiftUI

struct RootTabView: View {
    var body: some View {
        TabView {
            TodayView()
                .tabItem { Label("Today", systemImage: "figure.strengthtraining.traditional") }
            ProgressHomeView()
                .tabItem { Label("Progress", systemImage: "chart.line.uptrend.xyaxis") }
            PhotoTimelineView()
                .tabItem { Label("Photos", systemImage: "photo.on.rectangle.angled") }
            CoachView()
                .tabItem { Label("Coach", systemImage: "camera.viewfinder") }
            MoreView()
                .tabItem { Label("More", systemImage: "ellipsis.circle") }
        }
    }
}

struct MoreView: View {
    var body: some View {
        NavigationStack {
            List {
                NavigationLink(destination: HistoryView()) {
                    Label("History", systemImage: "clock.arrow.circlepath")
                }
                NavigationLink(destination: ExerciseLibraryView()) {
                    Label("Exercises", systemImage: "dumbbell.fill")
                }
                NavigationLink(destination: PlansView()) {
                    Label("Plans", systemImage: "list.bullet.rectangle")
                }
                NavigationLink(destination: SettingsView()) {
                    Label("Settings", systemImage: "gearshape.fill")
                }
            }
            .navigationTitle("More")
        }
    }
}
