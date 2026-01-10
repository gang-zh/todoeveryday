//
//  todoeverydayApp.swift
//  todoeveryday
//
//  Created by Gang Zhang on 1/6/26.
//

import SwiftUI
import SwiftData

@main
struct todoeverydayApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            DailyTodoList.self,
            TodoItem.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            print("⚠️ ERROR: Could not create ModelContainer: \(error)")
            print("⚠️ This usually means the database schema has changed.")
            print("⚠️ To fix this, delete the old database by running in Terminal:")
            print("⚠️ rm -rf ~/Library/Containers/skywhat.todoeveryday/Data/Library/Application\\ Support/default.store*")
            print("⚠️ Falling back to in-memory storage (data will not persist)...")

            // Fallback to in-memory storage so the app can still launch
            let memoryConfig = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            do {
                return try ModelContainer(for: schema, configurations: [memoryConfig])
            } catch {
                fatalError("Could not create in-memory ModelContainer: \(error)")
            }
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
