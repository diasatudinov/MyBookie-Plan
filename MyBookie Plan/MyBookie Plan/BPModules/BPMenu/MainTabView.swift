//
//  MainTabView.swift
//  MyBookie Plan
//
//

import SwiftUI

// MARK: - Main Tabs

enum AppTab: Int, CaseIterable {
    case home
    case calendar
    case bookings
    case analytics
    case profile
    
    var title: String {
        switch self {
        case .home: return "Home"
        case .calendar: return "Calendar"
        case .bookings: return "Bookings"
        case .analytics: return "Analytics"
        case .profile: return "Profile"
        }
    }
    
    var icon: String {
        switch self {
        case .home: return "house"
        case .calendar: return "calendar"
        case .bookings: return "book"
        case .analytics: return "chart.line.uptrend.xyaxis"
        case .profile: return "person"
        }
    }
    
    var selectedIcon: String {
        switch self {
        case .home: return "house.fill"
        case .calendar: return "calendar"
        case .bookings: return "book.fill"
        case .analytics: return "chart.line.uptrend.xyaxis"
        case .profile: return "person.fill"
        }
    }
}

struct MainTabView: View {
    @State private var selectedTab: AppTab = .home
    
    var body: some View {
        VStack(spacing: 0) {
            currentScreen
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(AppTheme.background.ignoresSafeArea())
                
            CustomTabBar(selectedTab: $selectedTab)
                
        }.ignoresSafeArea(edges: .bottom)
    }
    
    @ViewBuilder
    private var currentScreen: some View {
        switch selectedTab {
        case .home:
            HomeView(selectedTab: $selectedTab)
            
        case .calendar:
            SportsCalendarView()
            
        case .bookings:
            BookingsView()
            
        case .analytics:
            AnalyticsView()
            
        case .profile:
            ProfileView()
        }
    }
}

struct CustomTabBar: View {
    @Binding var selectedTab: AppTab

    var body: some View {
        VStack(spacing: 0) {
            Divider()
                .background(Color.white.opacity(0.08))

            HStack(spacing: 0) {
                ForEach(AppTab.allCases, id: \.self) { tab in
                    CustomTabBarItem(
                        tab: tab,
                        isSelected: selectedTab == tab
                    ) {
                        withAnimation(.spring(response: 0.28, dampingFraction: 0.8)) {
                            selectedTab = tab
                        }
                    }
                }
            }
            .padding(.top, 10)
            .padding(.bottom, 8)
            .background(AppTheme.card)

            Rectangle()
                .fill(Color.black)
                .frame(height: 18)
        }
        .background(AppTheme.card)
    }
}

struct CustomTabBarItem: View {
    let tab: AppTab
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: isSelected ? tab.selectedIcon : tab.icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(isSelected ? AppTheme.orange : .gray)

                Text(tab.title)
                    .font(.caption2)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundColor(isSelected ? AppTheme.orange : .gray)

                Capsule()
                    .fill(isSelected ? AppTheme.orange : Color.clear)
                    .frame(width: 28, height: 3)
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    MainTabView()
        .environmentObject(AppStore())
}
