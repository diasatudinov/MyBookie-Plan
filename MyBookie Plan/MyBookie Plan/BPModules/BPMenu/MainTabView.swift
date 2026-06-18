struct MainTabView: View {
    @State private var selectedTab: AppTab = .home

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView(selectedTab: $selectedTab)
                .tag(AppTab.home)
                .tabItem {
                    Label("Home", systemImage: "house")
                }

            SportsCalendarView()
                .tag(AppTab.calendar)
                .tabItem {
                    Label("Calendar", systemImage: "calendar")
                }

            BookingsView()
                .tag(AppTab.bookings)
                .tabItem {
                    Label("Bookings", systemImage: "book")
                }

            AnalyticsView()
                .tag(AppTab.analytics)
                .tabItem {
                    Label("Analytics", systemImage: "chart.line.uptrend.xyaxis")
                }

            ProfileView()
                .tag(AppTab.profile)
                .tabItem {
                    Label("Profile", systemImage: "person")
                }
        }
        .tint(AppTheme.orange)
    }
}