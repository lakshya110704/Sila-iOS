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
        NavigationView {
            List {
                ForEach(tasks) { task in
                    HStack {
                        Button(action: {
                            task.completed.toggle()
                            try? viewContext.save()
                        }) {
                            Image(systemName: task.completed ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(task.completed ? .green : .gray)
                        }

                        VStack(alignment: .leading) {
                            Text(task.title ?? "Untitled")
                                .font(.headline)
                                .strikethrough(task.completed, color: .gray)
                            Text(task.subject ?? "No Subject")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }

                        Spacer()
                        Text("\(task.duration) min")
                    }
                }
                .onDelete(perform: deleteTask)
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
        try? viewContext.save()
    }
}
