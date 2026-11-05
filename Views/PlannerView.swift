//
//  PlannerView.swift
//  Sila
//
//  Created by Lakshya Mehta on 07/08/25.
//


import SwiftUI
import CoreData

struct PlannerView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \StudyTask.date, ascending: true)],
        animation: .default
    )
    private var tasks: FetchedResults<StudyTask>

    @State private var showingAddTask = false

    var body: some View {
        NavigationStack {
            List {
                ForEach(tasks) { task in
                    HStack {
                        Button(action: {
                            task.toggleCompleted()
                            save()
                        }) {
                            Image(systemName: task.completed ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(task.completed ? .green : .gray)
                        }
                        .buttonStyle(.borderless)
                        .accessibilityLabel(task.completed ? "Mark incomplete" : "Mark complete")

                        VStack(alignment: .leading) {
                            Text(task.title ?? "Untitled")
                                .font(.headline)
                                .strikethrough(task.completed, color: .gray)
                            Text(task.subject.flatMap { $0.isEmpty ? nil : $0 } ?? "No Subject")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            if let date = task.date {
                                Text(date.formatted(date: .abbreviated, time: .shortened))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }

                        Spacer()
                        Text("\(task.duration) min")
                    }
                }
                .onDelete(perform: deleteTask)
            }
            .overlay {
                if tasks.isEmpty {
                    ContentUnavailableView("No Tasks", systemImage: "calendar.badge.plus",
                                           description: Text("Tap + to plan a study session."))
                }
            }
            .navigationTitle("Study Planner")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddTask.toggle()
                    } label: {
                        Label("Add Task", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddTask) {
                AddTaskView()
                    .environment(\.managedObjectContext, viewContext)
            }
        }
    }

    private func deleteTask(at offsets: IndexSet) {
        for index in offsets {
            viewContext.delete(tasks[index])
        }
        save()
    }

    private func save() {
        do {
            try viewContext.save()
        } catch {
            viewContext.rollback()
        }
    }
}
