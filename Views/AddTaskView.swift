//
//  AddTaskView.swift
//  Sila
//
//  Created by Lakshya Mehta on 07/08/25.
//


import SwiftUI

struct AddTaskView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var subject = ""
    @State private var date = Date()
    @State private var duration = 30

    var body: some View {
        NavigationView {
            Form {
                TextField("Title", text: $title)
                TextField("Subject", text: $subject)
                DatePicker("Date", selection: $date)
                Stepper("\(duration) minutes", value: $duration, in: 5...240, step: 5)
            }
            .navigationTitle("New Study Task")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        addTask()
                        dismiss()
                    }
                    .disabled(title.isEmpty)
                }
            }
        }
    }

    private func addTask() {
        let newTask = StudyTask(context: viewContext)
        newTask.title = title
        newTask.subject = subject
        newTask.date = date
        newTask.duration = Int64(duration)
        newTask.completed = false

        try? viewContext.save()
    }
}