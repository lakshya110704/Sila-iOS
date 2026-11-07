import SwiftUI
import CoreData

struct ContentView: View {
    private enum Screen {
        case planner, timer, summary
    }

    private let context: NSManagedObjectContext
    // Owned here so the planner can hand a task to the timer. @State, so its ticks only redraw the timer screen.
    @State private var timer: TimerViewModel
    @State private var screen = Screen.planner

    init(context: NSManagedObjectContext) {
        self.context = context
        _timer = State(initialValue: TimerViewModel(onSessionEnd: { mode, startedAt, endedAt, finished, focusedSeconds, taskURL in
            TimerSession.record(mode: mode, startedAt: startedAt, endedAt: endedAt, finished: finished, focusedSeconds: focusedSeconds,
                                task: StudyTask.find(taskURL, in: context), in: context)
        }))
    }

    var body: some View {
        TabView(selection: $screen) {
            PlannerView { task in
                timer.focus(on: task.objectID.uriRepresentation())
                screen = .timer
            }
            .tabItem {
                Label("Planner", systemImage: "calendar")
            }
            .tag(Screen.planner)

            TimerDashboardView(context: context, viewModel: timer)
                .tabItem {
                    Label("Timer", systemImage: "timer")
                }
                .tag(Screen.timer)

            ProductivitySummaryView(context: context)
                .tabItem {
                    Label("Summary", systemImage: "chart.bar.fill")
                }
                .tag(Screen.summary)
        }
    }
}
