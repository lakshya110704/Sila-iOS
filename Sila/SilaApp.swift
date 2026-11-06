//
//  SilaApp.swift
//  Sila
//
//  Created by Lakshya Mehta on 07/08/25.
//

import SwiftUI
import UserNotifications

@main
struct SilaApp: App {
    let persistenceController = PersistenceController.shared
    private let notificationDelegate = ForegroundNotificationDelegate()

    init() {
        UNUserNotificationCenter.current().delegate = notificationDelegate
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
