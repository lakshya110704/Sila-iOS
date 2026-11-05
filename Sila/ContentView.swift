import SwiftUI

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext

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

            ProductivitySummaryView(context: viewContext)
                .tabItem {
                    Label("Summary", systemImage: "chart.bar.fill")
                }
        }
    }
}
