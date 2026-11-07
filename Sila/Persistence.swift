//
//  Persistence.swift
//  Sila
//
//  Created by Lakshya Mehta on 07/08/25.
//

import CoreData

extension StudyTask {
    /// Sets the fields the form edits. Completion is left alone, so the Summary keeps counting it on the same day.
    func update(title: String, subject: String, date: Date, duration: Int) {
        self.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        self.subject = subject.trimmingCharacters(in: .whitespacesAndNewlines)
        self.date = date
        self.duration = Int64(duration)
    }

    func toggleCompleted(now: Date = Date()) {
        completed.toggle()
        completedAt = completed ? now : nil
    }

    var focusedMinutes: Int {
        ((sessions as? Set<TimerSession>) ?? []).reduce(0) { $0 + $1.countedSeconds } / 60
    }

    var durationLabel: String {
        focusedMinutes > 0 ? "\(focusedMinutes) of \(duration) min" : "\(duration) min"
    }

    static func find(_ url: URL?, in context: NSManagedObjectContext) -> StudyTask? {
        guard let url, let id = context.persistentStoreCoordinator?.managedObjectID(forURIRepresentation: url) else { return nil }
        return (try? context.existingObject(with: id)) as? StudyTask
    }
}

extension TimerSession {
    static func record(mode: TimerMode, startedAt: Date, endedAt: Date, finished: Bool, focusedSeconds: Int? = nil,
                       task: StudyTask? = nil, in context: NSManagedObjectContext) {
        // By name because +[TimerSession entity] is ambiguous when several containers have loaded the model.
        let session = NSEntityDescription.insertNewObject(forEntityName: "TimerSession", into: context) as! TimerSession
        session.mode = mode.rawValue
        session.startedAt = startedAt
        session.endedAt = endedAt
        session.finished = finished
        session.focusedSeconds = focusedSeconds.map { NSNumber(value: $0) }
        session.task = task
        do {
            try context.save()
        } catch {
            context.rollback()
        }
    }
}

extension TimerSession {
    var isFocus: Bool {
        mode != TimerMode.breakMode.rawValue
    }

    /// Sessions saved before focusedSeconds existed have none. Their start and end can include paused time, so cap them at the mode's length.
    var countedSeconds: Int {
        if let focusedSeconds { return focusedSeconds.intValue }
        guard let length = mode.flatMap(TimerMode.init(rawValue:))?.seconds, let startedAt, let endedAt else { return 0 }
        return finished ? length : min(length, Int(endedAt.timeIntervalSince(startedAt)))
    }
}

struct PersistenceController {
    // UI tests pass this flag so they start from an empty store each launch.
    static let shared = PersistenceController(inMemory: CommandLine.arguments.contains("--in-memory-store"))

    @MainActor
    static let preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        for _ in 0..<10 {
            let newTask = StudyTask(context: viewContext)
            newTask.title = "Sample Task"
            newTask.subject = "Math"
            newTask.date = Date()
            newTask.duration = 45
            newTask.completed = false
        }
        do {
            try viewContext.save()
        } catch {
            // Replace this implementation with code to handle the error appropriately.
            // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return result
    }()

    let container: NSPersistentContainer

    init(inMemory: Bool = false, storeURL: URL? = nil) {
        container = NSPersistentContainer(name: "Sila")
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        } else if let storeURL {
            container.persistentStoreDescriptions.first!.url = storeURL
        }
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.

                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
}
