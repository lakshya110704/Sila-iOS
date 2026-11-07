//
//  AddTaskView.swift
//  Sila
//
//  Created by Lakshya Mehta on 07/08/25.
//


import SwiftUI
import CoreData

struct AddTaskView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss

    @State private var title: String
    @State private var subject: String
    @State private var date: Date
    @State private var duration: Int
    @State private var saveFailed = false

    private let task: StudyTask?
    private let onSave: (Date) -> Void

    /// Pass a task to edit it. Without one, the form adds a new task on initialDate.
    init(task: StudyTask? = nil, initialDate: Date = Date(), onSave: @escaping (Date) -> Void = { _ in }) {
        self.task = task
        _title = State(initialValue: task?.title ?? "")
        _subject = State(initialValue: task?.subject ?? "")
        _date = State(initialValue: task?.date ?? initialDate)
        _duration = State(initialValue: task.map { Int($0.duration) } ?? 30)
        self.onSave = onSave
    }

    static func isValid(title: String, duration: Int) -> Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && duration > 0
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Title", text: $title)
                    TextField("Subject", text: $subject)
                    DatePicker("Date", selection: $date)
                    Stepper("\(duration) minutes", value: $duration, in: 5...240, step: 5)
                }
                .listRowBackground(Color.card)
            }
            .scrollContentBackground(.hidden)
            .background(Color.paper)
            .navigationTitle(task == nil ? "New Study Task" : "Edit Study Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveTask()
                    }
                    .disabled(!Self.isValid(title: title, duration: duration))
                }
            }
            .alert("Couldn't save task", isPresented: $saveFailed) {
                Button("OK", role: .cancel) {}
            }
        }
    }

    private func saveTask() {
        (task ?? StudyTask(context: viewContext)).update(title: title, subject: subject, date: date, duration: duration)

        do {
            try viewContext.save()
            onSave(date)
            dismiss()
        } catch {
            viewContext.rollback()
            saveFailed = true
        }
    }
}
