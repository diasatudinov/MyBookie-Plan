//
//  MyBookie_PlanApp.swift
//  MyBookie Plan
//
//

import SwiftUI

@main
struct MyBookie_PlanApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(AppStore())
        }
    }
}
