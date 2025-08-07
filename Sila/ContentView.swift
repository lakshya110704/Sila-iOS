import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            PlannerView()
                .tabItem {
                    Label("Planner", systemImage: "calendar")
                }

            TimerDashboardView()
                .tabItem {
                    Label("Timer", systemImage: "timer")
                }

            ProductivitySummaryView()
                .tabItem {
                    Label("Summary", systemImage: "chart.bar.fill")
                }
        }
    }
}
