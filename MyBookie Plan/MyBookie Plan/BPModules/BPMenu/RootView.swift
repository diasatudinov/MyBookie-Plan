//
//  RootView.swift
//  MyBookie Plan
//
//

import SwiftUI

// MARK: - Root

struct RootView: View {
    @EnvironmentObject private var store: AppStore

    var body: some View {
        if store.isLoggedIn {
            MainTabView()
        } else {
            AuthenticationView()
        }
    }
}

#Preview {
    RootView()
        .environmentObject(AppStore())
}
