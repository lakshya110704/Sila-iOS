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
    @State private var editingTask: StudyTask?
    @State private var weekStart = PlannerWeek.start(of: Date())

    private var isThisWeek: Bool {
        weekStart == PlannerWeek.start(of: Date())
    }

    private var daysWithTasks: [PlannerDay] {
        PlannerWeek.days(from: weekStart, tasks: Array(tasks)).filter { !$0.tasks.isEmpty }
    }

    private var weekLabel: String {
        let lastDay = Calendar.current.date(byAdding: .day, value: 6, to: weekStart)!
        let format = Date.FormatStyle().month(.abbreviated).day()
        return "\(weekStart.formatted(format)) to \(lastDay.formatted(format))"
    }

    var body: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .topTrailing) {
                ScreenTitle(text: "Study Planner")
                Button {
                    showingAddTask.toggle()
                } label: {
                    Label("Add Task", systemImage: "plus")
                        .labelStyle(.iconOnly)
                        .font(.title2)
                        .frame(minWidth: 44, minHeight: 44)
                        .contentShape(Rectangle())
                }
                .padding(.top, 8)
                .padding(.trailing, 8)
            }
            weekSwitcher
            List {
                ForEach(daysWithTasks) { day in
                    Section {
                        ForEach(day.tasks) { task in
                            row(for: task)
                                .listRowBackground(Color.card)
                        }
                        .onDelete { offsets in
                            deleteTask(from: day.tasks, at: offsets)
                        }
                    } header: {
                        SectionTitle(text: day.date.formatted(.dateTime.weekday(.wide).month(.abbreviated).day()))
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .overlay {
                if daysWithTasks.isEmpty {
                    ContentUnavailableView("No Tasks This Week", systemImage: "calendar.badge.plus",
                                           description: Text("Tap + to plan a study session."))
                }
            }
            .sheet(isPresented: $showingAddTask) {
                AddTaskView(initialDate: isThisWeek ? Date() : weekStart) { savedDate in
                    weekStart = PlannerWeek.start(of: savedDate)
                }
                .environment(\.managedObjectContext, viewContext)
            }
            .sheet(item: $editingTask) { task in
                AddTaskView(task: task) { savedDate in
                    weekStart = PlannerWeek.start(of: savedDate)
                }
                .environment(\.managedObjectContext, viewContext)
            }
        }
        .background(Color.paper)
    }

    private var weekSwitcher: some View {
        HStack {
            Button {
                changeWeek(by: -1)
            } label: {
                Image(systemName: "chevron.left")
                    .frame(minWidth: 44, minHeight: 44)
                    .contentShape(Rectangle())
            }
            .accessibilityLabel("Previous week")

            Spacer()
            VStack {
                Text(weekLabel)
                    .font(.serif(.headline))
                    .accessibilityIdentifier("weekLabel")
                if !isThisWeek {
                    Button("This Week") {
                        weekStart = PlannerWeek.start(of: Date())
                    }
                    .font(.subheadline)
                }
            }
            Spacer()

            Button {
                changeWeek(by: 1)
            } label: {
                Image(systemName: "chevron.right")
                    .frame(minWidth: 44, minHeight: 44)
                    .contentShape(Rectangle())
            }
            .accessibilityLabel("Next week")
        }
        .padding(.horizontal, 8)
    }

    private func row(for task: StudyTask) -> some View {
        HStack {
            Button(action: {
                task.toggleCompleted()
                save()
            }) {
                Image(systemName: task.completed ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundColor(task.completed ? .accentColor : .secondary)
                    .frame(minWidth: 44, minHeight: 44)
                    .contentShape(Rectangle())
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
                .font(.serif(.footnote))
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Color.accentColor.opacity(0.14), in: Capsule())
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
                .accessibilityHidden(true)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            editingTask = task
        }
        .accessibilityAction(named: "Edit") {
            editingTask = task
        }
    }

    private func changeWeek(by weeks: Int) {
        weekStart = Calendar.current.date(byAdding: .weekOfYear, value: weeks, to: weekStart)!
    }

    private func deleteTask(from dayTasks: [StudyTask], at offsets: IndexSet) {
        for index in offsets {
            viewContext.delete(dayTasks[index])
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
