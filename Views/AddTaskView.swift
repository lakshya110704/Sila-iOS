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

    @State private var title = ""
    @State private var subject = ""
    @State private var date = Date()
    @State private var duration = 30
    @State private var saveFailed = false

    private var trimmedTitle: String {
        title.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        NavigationStack {
            Form {
                TextField("Title", text: $title)
                TextField("Subject", text: $subject)
                DatePicker("Date", selection: $date)
                Stepper("\(duration) minutes", value: $duration, in: 5...240, step: 5)
            }
            .navigationTitle("New Study Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        addTask()
                    }
                    .disabled(trimmedTitle.isEmpty)
                }
            }
            .alert("Couldn't save task", isPresented: $saveFailed) {
                Button("OK", role: .cancel) {}
            }
        }
    }

    private func addTask() {
        let newTask = StudyTask(context: viewContext)
        newTask.title = trimmedTitle
        newTask.subject = subject.trimmingCharacters(in: .whitespacesAndNewlines)
        newTask.date = date
        newTask.duration = Int64(duration)
        newTask.completed = false

        do {
            try viewContext.save()
            dismiss()
        } catch {
            viewContext.rollback()
            saveFailed = true
        }
    }
}
