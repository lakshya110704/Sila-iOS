//
//  SilaApp.swift
//  Sila
//
//  Created by Lakshya Mehta on 07/08/25.
//

import SwiftUI

@main
struct SilaApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
