//
//  RakumiruApp.swift
//  Rakumiru
//
//  Created by tetsu.kuribayashi on 2024/06/03.
//

import SwiftUI

@main
struct RakumiruApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
