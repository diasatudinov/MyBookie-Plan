//
//  MyBookiePlanApp.swift
//  MyBookie Plan
//
//  Created by Dias Atudinov on 15.06.2026.
//


import SwiftUI
import Charts
import CoreImage.CIFilterBuiltins
import UIKit
import UserNotifications

// MARK: - App

@main
struct MyBookiePlanApp: App {
    @StateObject private var store = AppStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .preferredColorScheme(.dark)
        }
    }
}

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

// MARK: - Theme

enum AppTheme {
    static let background = Color(red: 0.04, green: 0.04, blue: 0.05)
    static let card = Color(red: 0.10, green: 0.10, blue: 0.11)
    static let field = Color(red: 0.14, green: 0.14, blue: 0.15)
    static let orange = Color.orange
    static let green = Color.green
    static let red = Color.red
    static let textSecondary = Color.gray
}

// MARK: - Models

enum Sport: String, CaseIterable, Identifiable, Codable {
    case football = "Football"
    case basketball = "Basketball"
    case mma = "MMA / UFC"
    case hockey = "Hockey"
    case tennis = "Tennis"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .football: return "⚽"
        case .basketball: return "🏀"
        case .mma: return "🥊"
        case .hockey: return "🏒"
        case .tennis: return "🎾"
        }
    }
}

enum BookingStatus: String, Codable {
    case pending = "Pending"
    case won = "Won"
    case lost = "Lost"
}

struct UserProfile: Codable {
    var fullName: String = "John Doe"
    var username: String = "johndoe"
    var email: String = "johndoe@example.com"
    var startingBankroll: Double = 2450
}

struct SportsEvent: Identifiable, Codable {
    var id = UUID()
    var date: Date
    var tournament: String
    var sport: Sport
    var teamOne: String
    var teamTwo: String
    var odds: Int
    var suggestedNote: String

    var title: String {
        "\(teamOne) vs \(teamTwo)"
    }
}

struct Booking: Identifiable, Codable {
    var id = UUID()
    var date: Date
    var tournament: String
    var sport: Sport
    var teamOne: String
    var teamTwo: String
    var odds: Int
    var stake: Double
    var note: String
    var status: BookingStatus

    var title: String {
        "\(teamOne) vs \(teamTwo)"
    }

    var profitIfWon: Double {
        if odds > 0 {
            return stake * Double(odds) / 100
        } else {
            return stake * 100 / Double(abs(odds))
        }
    }

    var bankrollDelta: Double {
        switch status {
        case .pending:
            return 0
        case .won:
            return profitIfWon
        case .lost:
            return -stake
        }
    }
}

struct Reward: Identifiable, Codable, Equatable {
    let id: String
    let title: String
    let description: String
    let instruction: String
    let expiresText: String

    var qrPayload: String {
        "MYBOOKIE_PLAN|\(id)|\(title)"
    }
}

struct UsedReward: Identifiable, Codable {
    var id: String { reward.id }
    var reward: Reward
    var usedAt: Date
}

struct BankrollPoint: Identifiable {
    let id = UUID()
    let title: String
    let value: Double
}

struct SportPerformance: Identifiable {
    let id = UUID()
    let sport: Sport
    let wins: Int
    let losses: Int

    var total: Int {
        wins + losses
    }

    var winRate: Double {
        guard total > 0 else { return 0 }
        return Double(wins) / Double(total) * 100
    }
}

// MARK: - Store

final class AppStore: ObservableObject {
    @Published var isLoggedIn: Bool = false {
        didSet { UserDefaults.standard.set(isLoggedIn, forKey: Keys.isLoggedIn) }
    }

    @Published var profile: UserProfile = UserProfile() {
        didSet { save(profile, key: Keys.profile) }
    }

    @Published var bookings: [Booking] = [] {
        didSet { save(bookings, key: Keys.bookings) }
    }

    @Published var usedRewards: [UsedReward] = [] {
        didSet { save(usedRewards, key: Keys.usedRewards) }
    }

    @Published var notificationsEnabled: Bool = true {
        didSet { UserDefaults.standard.set(notificationsEnabled, forKey: Keys.notificationsEnabled) }
    }

    let sportsEvents: [SportsEvent] = SportsEvent.samples
    let rewards: [Reward] = Reward.samples

    init() {
        isLoggedIn = UserDefaults.standard.bool(forKey: Keys.isLoggedIn)
        profile = load(UserProfile.self, key: Keys.profile) ?? UserProfile()
        bookings = load([Booking].self, key: Keys.bookings) ?? Booking.samples
        usedRewards = load([UsedReward].self, key: Keys.usedRewards) ?? []
        notificationsEnabled = UserDefaults.standard.object(forKey: Keys.notificationsEnabled) as? Bool ?? true
    }

    var bankroll: Double {
        profile.startingBankroll + bookings.reduce(0) { $0 + $1.bankrollDelta }
    }

    var totalProfit: Double {
        bookings.reduce(0) { $0 + $1.bankrollDelta }
    }

    var roi: Double {
        guard profile.startingBankroll > 0 else { return 0 }
        return totalProfit / profile.startingBankroll * 100
    }

    var completedBookings: [Booking] {
        bookings
            .filter { $0.status != .pending }
            .sorted { $0.date > $1.date }
    }

    var upcomingBookings: [Booking] {
        bookings
            .filter { $0.status == .pending }
            .sorted { $0.date < $1.date }
    }

    var winRate: Double {
        let completed = completedBookings
        guard !completed.isEmpty else { return 0 }

        let wins = completed.filter { $0.status == .won }.count
        return Double(wins) / Double(completed.count) * 100
    }

    var averageOdds: Double {
        guard !bookings.isEmpty else { return 0 }
        let sum = bookings.reduce(0) { $0 + $1.odds }
        return Double(sum) / Double(bookings.count)
    }

    var nextBooking: Booking? {
        upcomingBookings.first
    }

    var activeRewards: [Reward] {
        let usedIds = Set(usedRewards.map { $0.reward.id })
        return rewards.filter { !usedIds.contains($0.id) }
    }

    func signIn(login: String, password: String) {
        let cleanLogin = login.trimmingCharacters(in: .whitespacesAndNewlines)

        if cleanLogin.contains("@") {
            profile.email = cleanLogin
            profile.username = cleanLogin.components(separatedBy: "@").first ?? "user"
            profile.fullName = profile.username.capitalized
        } else if !cleanLogin.isEmpty {
            profile.username = cleanLogin
            profile.fullName = cleanLogin.capitalized
            profile.email = "\(cleanLogin.lowercased())@example.com"
        }

        isLoggedIn = true
    }

    func logout() {
        isLoggedIn = false
    }

    func clearCache() {
        bookings = Booking.samples
        usedRewards = []
        profile.startingBankroll = 2450
    }

    func setNotifications(_ enabled: Bool) {
        notificationsEnabled = enabled

        if enabled {
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { _, _ in }
        }
    }

    func addBooking(from event: SportsEvent, stake: Double = 100, note: String? = nil) {
        let booking = Booking(
            date: event.date,
            tournament: event.tournament,
            sport: event.sport,
            teamOne: event.teamOne,
            teamTwo: event.teamTwo,
            odds: event.odds,
            stake: stake,
            note: note ?? event.suggestedNote,
            status: .pending
        )

        bookings.append(booking)
        scheduleReminderIfNeeded(for: booking)
    }

    func addBooking(
        date: Date,
        tournament: String,
        sport: Sport,
        teamOne: String,
        teamTwo: String,
        odds: Int,
        stake: Double,
        note: String
    ) {
        let booking = Booking(
            date: date,
            tournament: tournament,
            sport: sport,
            teamOne: teamOne,
            teamTwo: teamTwo,
            odds: odds,
            stake: stake,
            note: note,
            status: .pending
        )

        bookings.append(booking)
        scheduleReminderIfNeeded(for: booking)
    }

    func updateStatus(for booking: Booking, status: BookingStatus) {
        guard let index = bookings.firstIndex(where: { $0.id == booking.id }) else { return }
        bookings[index].status = status
    }

    func useReward(_ reward: Reward) {
        guard !usedRewards.contains(where: { $0.reward.id == reward.id }) else { return }
        usedRewards.append(UsedReward(reward: reward, usedAt: Date()))
    }

    func performanceBySport() -> [SportPerformance] {
        Sport.allCases.map { sport in
            let sportBookings = completedBookings.filter { $0.sport == sport }
            let wins = sportBookings.filter { $0.status == .won }.count
            let losses = sportBookings.filter { $0.status == .lost }.count

            return SportPerformance(
                sport: sport,
                wins: wins,
                losses: losses
            )
        }
    }

    func bankrollHistory() -> [BankrollPoint] {
        let sorted = completedBookings.sorted { $0.date < $1.date }

        var value = profile.startingBankroll
        var result: [BankrollPoint] = [
            BankrollPoint(title: "Start", value: value)
        ]

        for booking in sorted {
            value += booking.bankrollDelta
            result.append(
                BankrollPoint(
                    title: booking.date.shortMonthDay,
                    value: value
                )
            )
        }

        if result.count == 1 {
            result.append(BankrollPoint(title: "Now", value: value))
        }

        return result
    }

    private func scheduleReminderIfNeeded(for booking: Booking) {
        guard notificationsEnabled else { return }

        let reminderDate = booking.date.addingTimeInterval(-30 * 60)
        guard reminderDate > Date() else { return }

        let content = UNMutableNotificationContent()
        content.title = "\(booking.sport.icon) Upcoming: \(booking.title)"
        content.body = "Do not forget to follow your virtual plan."
        content.sound = .default

        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: reminderDate
        )

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(
            identifier: booking.id.uuidString,
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request)
    }

    private enum Keys {
        static let isLoggedIn = "mybookie_isLoggedIn"
        static let profile = "mybookie_profile"
        static let bookings = "mybookie_bookings"
        static let usedRewards = "mybookie_usedRewards"
        static let notificationsEnabled = "mybookie_notificationsEnabled"
    }

    private func save<T: Encodable>(_ value: T, key: String) {
        guard let data = try? JSONEncoder().encode(value) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }

    private func load<T: Decodable>(_ type: T.Type, key: String) -> T? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }
}

// MARK: - Sample Data

extension SportsEvent {
    static let samples: [SportsEvent] = [
        SportsEvent(
            date: Date.demoDate(daysFromToday: 1, hour: 19),
            tournament: "NBA",
            sport: .basketball,
            teamOne: "Lakers",
            teamTwo: "Warriors",
            odds: 175,
            suggestedNote: "Lakers to win by 5+ points."
        ),
        SportsEvent(
            date: Date.demoDate(daysFromToday: 2, hour: 15),
            tournament: "Premier League",
            sport: .football,
            teamOne: "Man City",
            teamTwo: "Liverpool",
            odds: -120,
            suggestedNote: "Over 2.5 goals."
        ),
        SportsEvent(
            date: Date.demoDate(daysFromToday: 3, hour: 22),
            tournament: "UFC 305",
            sport: .mma,
            teamOne: "Adesanya",
            teamTwo: "Pereira",
            odds: 200,
            suggestedNote: "Main event. Watch line movement."
        ),
        SportsEvent(
            date: Date.demoDate(daysFromToday: 4, hour: 18),
            tournament: "French Open",
            sport: .tennis,
            teamOne: "Alcaraz",
            teamTwo: "Sinner",
            odds: 110,
            suggestedNote: "Long rally match expected."
        ),
        SportsEvent(
            date: Date.demoDate(daysFromToday: 5, hour: 20),
            tournament: "NHL",
            sport: .hockey,
            teamOne: "Rangers",
            teamTwo: "Bruins",
            odds: -105,
            suggestedNote: "Goalkeeper form is important."
        )
    ]
}

extension Booking {
    static let samples: [Booking] = [
        Booking(
            date: Date.demoDate(daysFromToday: 1, hour: 19),
            tournament: "NBA",
            sport: .basketball,
            teamOne: "Lakers",
            teamTwo: "Warriors",
            odds: 175,
            stake: 100,
            note: "Lakers to win by 5+ points.",
            status: .pending
        ),
        Booking(
            date: Date.demoDate(daysFromToday: 2, hour: 15),
            tournament: "Premier League",
            sport: .football,
            teamOne: "Man City",
            teamTwo: "Liverpool",
            odds: -120,
            stake: 150,
            note: "Over 2.5 goals.",
            status: .pending
        ),
        Booking(
            date: Date.demoDate(daysFromToday: -1, hour: 20),
            tournament: "NBA",
            sport: .basketball,
            teamOne: "Bulls",
            teamTwo: "Celtics",
            odds: -110,
            stake: 80,
            note: "Celtics to win.",
            status: .won
        ),
        Booking(
            date: Date.demoDate(daysFromToday: -2, hour: 21),
            tournament: "La Liga",
            sport: .football,
            teamOne: "Real Madrid",
            teamTwo: "Barcelona",
            odds: 140,
            stake: 120,
            note: "Barcelona to win.",
            status: .lost
        ),
        Booking(
            date: Date.demoDate(daysFromToday: -4, hour: 17),
            tournament: "French Open",
            sport: .tennis,
            teamOne: "Nadal",
            teamTwo: "Rune",
            odds: 130,
            stake: 90,
            note: "Nadal in good form.",
            status: .won
        )
    ]
}

extension Reward {
    static let samples: [Reward] = [
        Reward(
            id: "risk_free_50",
            title: "$50 Risk-Free Weekend Bet",
            description: "Place a virtual plan for any Premier League match this weekend. If it loses, your discipline still gets rewarded.",
            instruction: "Scan this QR code on MyBookie in the Promo section to activate the fake reward.",
            expiresText: "48 hours"
        ),
        Reward(
            id: "crypto_match",
            title: "100% Crypto Deposit Match",
            description: "A fake promo for planning discipline. Your virtual deposit match is capped at $250.",
            instruction: "Scan this QR code during the crypto deposit flow.",
            expiresText: "7 days"
        ),
        Reward(
            id: "vip_table",
            title: "VIP Table & Free Beer",
            description: "Offline-style fake bonus for a partner sports bar.",
            instruction: "Show this QR code to the bartender or venue administrator.",
            expiresText: "End of month"
        ),
        Reward(
            id: "free_spins",
            title: "25 Free Spins: Halftime Break",
            description: "Fake reward for halftime engagement.",
            instruction: "Scan this QR code in the mobile version of MyBookie Casino.",
            expiresText: "24 hours"
        ),
        Reward(
            id: "parlay_cashback",
            title: "15% Parlay Cashback",
            description: "A fake cashback reward for disciplined parlay planning.",
            instruction: "Enter the generated promo code in the Cashier section.",
            expiresText: "14 days"
        )
    ]
}

// MARK: - Main Tabs

enum AppTab: Int {
    case home
    case calendar
    case bookings
    case analytics
    case profile
}

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

// MARK: - Authentication

struct AuthenticationView: View {
    @EnvironmentObject private var store: AppStore

    @State private var login = ""
    @State private var password = ""
    @State private var isPasswordVisible = false

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            VStack(spacing: 26) {
                Spacer()

                HStack(spacing: 0) {
                    Text("My")
                        .font(.largeTitle.bold())
                        .foregroundColor(.white)

                    Text("Bookie")
                        .font(.largeTitle.bold())
                        .foregroundColor(AppTheme.orange)
                }

                VStack(spacing: 8) {
                    Text("Welcome back")
                        .font(.title2.bold())

                    Text("Sign in to continue planning your sports strategy")
                        .font(.subheadline)
                        .foregroundColor(AppTheme.textSecondary)
                        .multilineTextAlignment(.center)
                }

                VStack(spacing: 18) {
                    AppTextField(
                        title: "Email or Username",
                        placeholder: "Enter your email",
                        icon: "envelope",
                        text: $login
                    )

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Password")
                            .font(.caption)
                            .foregroundColor(.gray)

                        HStack {
                            Image(systemName: "lock")
                                .foregroundColor(.gray)

                            if isPasswordVisible {
                                TextField("Enter your password", text: $password)
                            } else {
                                SecureField("Enter your password", text: $password)
                            }

                            Button {
                                isPasswordVisible.toggle()
                            } label: {
                                Image(systemName: isPasswordVisible ? "eye.slash" : "eye")
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding()
                        .background(AppTheme.field)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                }

                Button {
                    store.signIn(login: login, password: password)
                } label: {
                    Text("Sign In")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(AppTheme.orange)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .padding(.top, 30)

                Text("18+ Virtual Planning Tool. Not a Gambling Product.")
                    .font(.caption)
                    .foregroundColor(.gray)

                Spacer()
            }
            .padding(24)
        }
    }
}

// MARK: - Home

struct HomeView: View {
    @EnvironmentObject private var store: AppStore
    @Binding var selectedTab: AppTab

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Good Afternoon")
                            .font(.title2.bold())

                        Text("Ready to plan your next win?")
                            .foregroundColor(.gray)
                    }

                    BankrollSummaryView()

                    if let next = store.nextBooking {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Next Booked Event")
                                    .font(.headline)

                                Spacer()

                                Button("View All") {
                                    selectedTab = .bookings
                                }
                                .foregroundColor(AppTheme.orange)
                            }

                            BookingCardView(booking: next)
                        }
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Quick Actions")
                            .font(.headline)

                        LazyVGrid(columns: [.init(), .init()], spacing: 12) {
                            QuickActionButton(title: "Book Event", icon: "plus") {
                                selectedTab = .bookings
                            }

                            QuickActionButton(title: "View Calendar", icon: "calendar") {
                                selectedTab = .calendar
                            }

                            QuickActionButton(title: "Analytics", icon: "chart.line.uptrend.xyaxis") {
                                selectedTab = .analytics
                            }

                            QuickActionButton(title: "Rewards", icon: "gift") {
                                selectedTab = .profile
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Recent Activity")
                            .font(.headline)

                        ForEach(store.completedBookings.prefix(3)) { booking in
                            ActivityRowView(booking: booking)
                        }
                    }
                }
                .padding()
            }
            .background(AppTheme.background.ignoresSafeArea())
        }
    }
}

struct BankrollSummaryView: View {
    @EnvironmentObject private var store: AppStore

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Total Bankroll")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))

                    Text(store.bankroll.money)
                        .font(.largeTitle.bold())
                }

                Spacer()

                Image(systemName: "dollarsign")
                    .font(.title2)
                    .padding()
                    .background(.white.opacity(0.18))
                    .clipShape(Circle())
            }

            HStack {
                SmallMetricView(title: "Total Profit", value: store.totalProfit.signedMoney)
                SmallMetricView(title: "ROI", value: "\(store.roi.signedPercent)")
            }
        }
        .padding()
        .background(
            LinearGradient(
                colors: [AppTheme.orange, Color.orange.opacity(0.75)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

struct SmallMetricView: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.white.opacity(0.8))

            Text(value)
                .font(.headline.bold())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.white.opacity(0.14))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

struct QuickActionButton: View {
    let title: String
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(AppTheme.orange)
                    .padding()
                    .background(AppTheme.orange.opacity(0.16))
                    .clipShape(Circle())

                Text(title)
                    .font(.subheadline.bold())
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 110)
            .background(AppTheme.card)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }
}

struct ActivityRowView: View {
    let booking: Booking

    var body: some View {
        HStack {
            Circle()
                .fill(booking.status == .won ? AppTheme.green : AppTheme.red)
                .frame(width: 8, height: 8)

            VStack(alignment: .leading, spacing: 3) {
                Text("\(booking.status.rawValue): \(booking.title)")
                    .font(.subheadline.bold())

                Text(booking.date.shortMonthDay)
                    .font(.caption)
                    .foregroundColor(.gray)
            }

            Spacer()

            Text(booking.bankrollDelta.signedMoney)
                .font(.subheadline.bold())
                .foregroundColor(booking.bankrollDelta >= 0 ? AppTheme.green : AppTheme.red)
        }
        .padding()
        .background(AppTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

// MARK: - Calendar

struct SportsCalendarView: View {
    @EnvironmentObject private var store: AppStore

    @State private var selectedSport: Sport?
    @State private var selectedEvent: SportsEvent?

    private var filteredEvents: [SportsEvent] {
        store.sportsEvents
            .filter { selectedSport == nil || $0.sport == selectedSport }
            .sorted { $0.date < $1.date }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    Text("Sports Calendar")
                        .font(.largeTitle.bold())

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            FilterButton(title: "All", isSelected: selectedSport == nil) {
                                selectedSport = nil
                            }

                            ForEach(Sport.allCases) { sport in
                                FilterButton(
                                    title: "\(sport.icon) \(sport.rawValue)",
                                    isSelected: selectedSport == sport
                                ) {
                                    selectedSport = sport
                                }
                            }
                        }
                    }

                    WeekCalendarStripView()

                    VStack(spacing: 14) {
                        ForEach(filteredEvents) { event in
                            Button {
                                selectedEvent = event
                            } label: {
                                SportsEventCardView(event: event)
                            }
                        }
                    }
                }
                .padding()
            }
            .background(AppTheme.background.ignoresSafeArea())
            .sheet(item: $selectedEvent) { event in
                EventDetailsSheet(event: event)
                    .presentationDetents([.medium])
            }
        }
    }
}

struct WeekCalendarStripView: View {
    private let days = Array(0..<7)

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "chevron.left")
                    .foregroundColor(.gray)

                Spacer()

                Label(Date().monthYear, systemImage: "calendar")
                    .font(.headline)

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
            }

            HStack {
                ForEach(days, id: \.self) { offset in
                    let date = Date.demoDate(daysFromToday: offset, hour: 12)

                    VStack(spacing: 8) {
                        Text(date.weekdayShort)
                            .font(.caption)
                            .foregroundColor(.gray)

                        Text(date.dayNumber)
                            .font(.headline)
                            .frame(width: 42, height: 42)
                            .background(offset == 1 ? AppTheme.orange : Color.clear)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding()
        .background(AppTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }
}

struct SportsEventCardView: View {
    let event: SportsEvent

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("\(event.sport.icon) \(event.sport.rawValue)")
                    .font(.caption.bold())
                    .foregroundColor(AppTheme.orange)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(AppTheme.orange.opacity(0.18))
                    .clipShape(Capsule())

                Text(event.tournament)
                    .font(.caption)
                    .foregroundColor(.gray)

                Spacer()

                Text(event.odds.oddsText)
                    .font(.headline.bold())
                    .foregroundColor(AppTheme.orange)
            }

            Text(event.title)
                .font(.headline)
                .foregroundColor(.white)

            HStack {
                Text(event.date.shortMonthDay)
                Text(event.date.shortTime)

                Spacer()

                Text("Book Event")
                    .font(.subheadline.bold())
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(AppTheme.orange.opacity(0.22))
                    .clipShape(Capsule())
            }
            .foregroundColor(.gray)
        }
        .padding()
        .background(AppTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }
}

struct EventDetailsSheet: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss

    let event: SportsEvent

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Capsule()
                .frame(width: 40, height: 5)
                .foregroundColor(.gray.opacity(0.4))
                .frame(maxWidth: .infinity)

            Text("Match Details")
                .font(.title2.bold())

            DetailLine(title: "Sport", value: "\(event.sport.icon) \(event.sport.rawValue)")
            DetailLine(title: "Tournament", value: event.tournament)
            DetailLine(title: "Match", value: event.title)
            DetailLine(title: "Date", value: event.date.shortMonthDay)
            DetailLine(title: "Time", value: event.date.shortTime)
            DetailLine(title: "Estimated Odds", value: event.odds.oddsText)
            DetailLine(title: "Strategy Note", value: event.suggestedNote)

            Button {
                store.addBooking(from: event)
                dismiss()
            } label: {
                Text("Book Event")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(AppTheme.orange)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }

            Spacer()
        }
        .padding()
        .background(AppTheme.background.ignoresSafeArea())
    }
}

// MARK: - Bookings

enum BookingSegment {
    case upcoming
    case completed
}

struct BookingsView: View {
    @EnvironmentObject private var store: AppStore

    @State private var segment: BookingSegment = .upcoming
    @State private var showCreateBooking = false
    @State private var selectedBooking: Booking?

    private var currentBookings: [Booking] {
        switch segment {
        case .upcoming:
            return store.upcomingBookings
        case .completed:
            return store.completedBookings
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    HStack {
                        Text("My Bookings")
                            .font(.largeTitle.bold())

                        Spacer()

                        Button {
                            showCreateBooking = true
                        } label: {
                            Image(systemName: "plus")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding()
                                .background(AppTheme.orange)
                                .clipShape(Circle())
                        }
                    }

                    HStack(spacing: 0) {
                        SegmentButton(
                            title: "Upcoming (\(store.upcomingBookings.count))",
                            isSelected: segment == .upcoming
                        ) {
                            segment = .upcoming
                        }

                        SegmentButton(
                            title: "Completed (\(store.completedBookings.count))",
                            isSelected: segment == .completed
                        ) {
                            segment = .completed
                        }
                    }
                    .padding(4)
                    .background(AppTheme.card)
                    .clipShape(RoundedRectangle(cornerRadius: 14))

                    VStack(spacing: 14) {
                        ForEach(currentBookings) { booking in
                            Button {
                                selectedBooking = booking
                            } label: {
                                BookingCardView(booking: booking)
                            }
                        }
                    }
                }
                .padding()
            }
            .background(AppTheme.background.ignoresSafeArea())
            .sheet(isPresented: $showCreateBooking) {
                NavigationStack {
                    CreateBookingView()
                }
            }
            .sheet(item: $selectedBooking) { booking in
                BookingDetailsSheet(booking: booking)
                    .presentationDetents([.medium, .large])
            }
        }
    }
}

struct BookingCardView: View {
    let booking: Booking

    private var borderColor: Color {
        switch booking.status {
        case .pending: return AppTheme.orange
        case .won: return AppTheme.green
        case .lost: return AppTheme.red
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("\(booking.sport.icon) \(booking.sport.rawValue)")
                    .font(.caption.bold())
                    .foregroundColor(AppTheme.orange)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(AppTheme.orange.opacity(0.18))
                    .clipShape(Capsule())

                Text(booking.tournament)
                    .font(.caption)
                    .foregroundColor(.gray)

                Text(booking.status.rawValue)
                    .font(.caption.bold())
                    .foregroundColor(borderColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(borderColor.opacity(0.14))
                    .clipShape(Capsule())

                Spacer()
            }

            Text(booking.title)
                .font(.headline)
                .foregroundColor(.white)

            Text(booking.note)
                .font(.subheadline)
                .foregroundColor(.gray)

            Divider()
                .background(.gray.opacity(0.4))

            HStack {
                Label(booking.date.shortMonthDay, systemImage: "calendar")
                Label(booking.date.shortTime, systemImage: "clock")

                Spacer()

                VStack(alignment: .trailing) {
                    Text(booking.odds.oddsText)
                        .font(.headline.bold())
                        .foregroundColor(AppTheme.orange)

                    Text("odds")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            .font(.caption)
            .foregroundColor(.gray)

            HStack {
                VStack(alignment: .leading) {
                    Text("Bankroll")
                        .font(.caption)
                        .foregroundColor(.gray)

                    Text(booking.stake.money)
                        .font(.headline.bold())
                }

                Spacer()

                if booking.status != .pending {
                    VStack(alignment: .trailing) {
                        Text("Profit / Loss")
                            .font(.caption)
                            .foregroundColor(.gray)

                        Text(booking.bankrollDelta.signedMoney)
                            .font(.headline.bold())
                            .foregroundColor(booking.bankrollDelta >= 0 ? AppTheme.green : AppTheme.red)
                    }
                }
            }
        }
        .padding()
        .background(AppTheme.card)
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(borderColor.opacity(0.6), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }
}

struct BookingDetailsSheet: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss

    let booking: Booking

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Capsule()
                .frame(width: 40, height: 5)
                .foregroundColor(.gray.opacity(0.4))
                .frame(maxWidth: .infinity)

            HStack {
                Text("Booking Details")
                    .font(.title2.bold())

                Spacer()

                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .foregroundColor(.white)
                }
            }

            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("\(booking.sport.icon) \(booking.sport.rawValue)")
                        .font(.caption.bold())
                        .foregroundColor(AppTheme.orange)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(AppTheme.orange.opacity(0.18))
                        .clipShape(Capsule())

                    Text(booking.tournament)
                        .foregroundColor(.gray)

                    Text(booking.status.rawValue)
                        .font(.caption.bold())
                        .foregroundColor(AppTheme.orange)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(AppTheme.orange.opacity(0.18))
                        .clipShape(Capsule())
                }

                DetailLine(title: "Match", value: booking.title)
                DetailLine(title: "Date", value: booking.date.shortMonthDay)
                DetailLine(title: "Time", value: booking.date.shortTime)
                DetailLine(title: "Estimated Odds", value: booking.odds.oddsText)
                DetailLine(title: "Virtual Stake", value: booking.stake.money)
                DetailLine(title: "Strategy Note", value: booking.note)
            }
            .padding()
            .background(AppTheme.card)
            .clipShape(RoundedRectangle(cornerRadius: 18))

            if booking.status == .pending {
                Button {
                    store.updateStatus(for: booking, status: .won)
                    dismiss()
                } label: {
                    Text("Mark as Won")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(AppTheme.green.opacity(0.25))
                        .foregroundColor(AppTheme.green)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }

                Button {
                    store.updateStatus(for: booking, status: .lost)
                    dismiss()
                } label: {
                    Text("Mark as Lost")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(AppTheme.red.opacity(0.25))
                        .foregroundColor(AppTheme.red)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
            }

            Spacer()
        }
        .padding()
        .background(AppTheme.background.ignoresSafeArea())
    }
}

struct CreateBookingView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss

    @State private var date = Date.demoDate(daysFromToday: 1, hour: 19)
    @State private var tournament = ""
    @State private var selectedSport: Sport = .basketball
    @State private var teamOne = ""
    @State private var teamTwo = ""
    @State private var odds = ""
    @State private var stake = ""
    @State private var note = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("Create Booking")
                    .font(.largeTitle.bold())

                DatePicker("Date & Time", selection: $date)
                    .datePickerStyle(.compact)
                    .padding()
                    .background(AppTheme.card)
                    .clipShape(RoundedRectangle(cornerRadius: 14))

                AppTextField(
                    title: "Tournament Name",
                    placeholder: "e.g. Premier League, NBA, UFC 305",
                    icon: "trophy",
                    text: $tournament
                )

                VStack(alignment: .leading, spacing: 10) {
                    Text("Sport Selector")
                        .font(.headline)

                    LazyVGrid(columns: [.init(), .init()], spacing: 10) {
                        ForEach(Sport.allCases) { sport in
                            Button {
                                selectedSport = sport
                            } label: {
                                Text("\(sport.icon) \(sport.rawValue)")
                                    .font(.subheadline.bold())
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(selectedSport == sport ? AppTheme.orange : AppTheme.card)
                                    .foregroundColor(.white)
                                    .clipShape(RoundedRectangle(cornerRadius: 14))
                            }
                        }
                    }
                }

                AppTextField(
                    title: "Team 1 / Player 1",
                    placeholder: "Team 1 / Player 1",
                    icon: "person",
                    text: $teamOne
                )

                AppTextField(
                    title: "Team 2 / Player 2",
                    placeholder: "Team 2 / Player 2",
                    icon: "person.2",
                    text: $teamTwo
                )

                AppTextField(
                    title: "Estimated Odds",
                    placeholder: "e.g. +175, -120",
                    icon: "plus.forwardslash.minus",
                    text: $odds
                )
                .keyboardType(.numbersAndPunctuation)

                AppTextField(
                    title: "Virtual Stake Amount",
                    placeholder: "0.00",
                    icon: "dollarsign",
                    text: $stake
                )
                .keyboardType(.decimalPad)

                VStack(alignment: .leading, spacing: 8) {
                    Label("Strategy Note / Reasoning", systemImage: "doc.text")
                        .font(.headline)
                        .foregroundColor(.white)

                    TextEditor(text: $note)
                        .frame(height: 120)
                        .padding(8)
                        .background(AppTheme.field)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }

                Button {
                    saveBooking()
                } label: {
                    Text("Save Booking")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(AppTheme.orange)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .padding(.top, 20)
            }
            .padding()
        }
        .background(AppTheme.background.ignoresSafeArea())
    }

    private func saveBooking() {
        let cleanOdds = Int(odds.replacingOccurrences(of: "+", with: "")) ?? 100
        let cleanStake = Double(stake.replacingOccurrences(of: ",", with: ".")) ?? 0

        store.addBooking(
            date: date,
            tournament: tournament.isEmpty ? "Custom Tournament" : tournament,
            sport: selectedSport,
            teamOne: teamOne.isEmpty ? "Team 1" : teamOne,
            teamTwo: teamTwo.isEmpty ? "Team 2" : teamTwo,
            odds: cleanOdds,
            stake: cleanStake,
            note: note.isEmpty ? "No strategy note." : note
        )

        dismiss()
    }
}

// MARK: - Bonus Hub

struct BonusHubView: View {
    @EnvironmentObject private var store: AppStore

    @State private var showUsedRewards = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                Text("Bonus Hub")
                    .font(.largeTitle.bold())

                HStack(spacing: 0) {
                    SegmentButton(
                        title: "Active Rewards (\(store.activeRewards.count))",
                        isSelected: !showUsedRewards
                    ) {
                        showUsedRewards = false
                    }

                    SegmentButton(
                        title: "Used Rewards (\(store.usedRewards.count))",
                        isSelected: showUsedRewards
                    ) {
                        showUsedRewards = true
                    }
                }
                .padding(4)
                .background(AppTheme.card)
                .clipShape(RoundedRectangle(cornerRadius: 14))

                if showUsedRewards {
                    ForEach(store.usedRewards) { item in
                        UsedRewardCardView(item: item)
                    }
                } else {
                    if let firstReward = store.activeRewards.first {
                        RewardQRCodeCardView(reward: firstReward)
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Your Active Rewards")
                            .font(.headline)
                            .foregroundColor(.gray)

                        ForEach(store.activeRewards) { reward in
                            RewardSmallCardView(reward: reward)
                        }
                    }
                }
            }
            .padding()
        }
        .background(AppTheme.background.ignoresSafeArea())
    }
}

struct RewardQRCodeCardView: View {
    @EnvironmentObject private var store: AppStore

    let reward: Reward

    var body: some View {
        VStack(spacing: 18) {
            QRCodeView(text: reward.qrPayload)
                .frame(width: 220, height: 220)
                .padding()
                .background(.white)
                .clipShape(RoundedRectangle(cornerRadius: 18))

            VStack(alignment: .leading, spacing: 8) {
                Text(reward.title)
                    .font(.title3.bold())

                Text(reward.description)
                    .foregroundColor(.gray)

                Label("Expires: \(reward.expiresText)", systemImage: "calendar")
                    .font(.subheadline)
                    .foregroundColor(.gray)

                Text("How to use: \(reward.instruction)")
                    .font(.subheadline)
                    .padding()
                    .background(AppTheme.orange.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Button {
                store.useReward(reward)
            } label: {
                Text("Mark Reward as Used")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(AppTheme.orange)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
        }
        .padding()
        .background(AppTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

struct RewardSmallCardView: View {
    let reward: Reward

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: "gift")
                .foregroundColor(AppTheme.orange)
                .padding()
                .background(AppTheme.orange.opacity(0.16))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(reward.title)
                    .font(.headline)

                Text(reward.description)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .lineLimit(2)
            }

            Spacer()

            VStack(alignment: .trailing) {
                Text("Expires")
                    .font(.caption)
                    .foregroundColor(.gray)

                Text(reward.expiresText)
                    .font(.caption.bold())
            }
        }
        .padding()
        .background(AppTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct UsedRewardCardView: View {
    let item: UsedReward

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: "checkmark.circle")
                .foregroundColor(AppTheme.green)

            VStack(alignment: .leading, spacing: 4) {
                Text(item.reward.title)
                    .font(.headline)

                Text("Used on \(item.usedAt.shortMonthDay)")
                    .font(.caption)
                    .foregroundColor(.gray)
            }

            Spacer()
        }
        .padding()
        .background(AppTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct QRCodeView: View {
    let text: String

    private let context = CIContext()
    private let filter = CIFilter.qrCodeGenerator()

    var body: some View {
        Image(uiImage: generateQRCode(from: text))
            .interpolation(.none)
            .resizable()
            .scaledToFit()
    }

    private func generateQRCode(from string: String) -> UIImage {
        filter.message = Data(string.utf8)
        filter.correctionLevel = "M"

        guard let outputImage = filter.outputImage else {
            return UIImage(systemName: "qrcode") ?? UIImage()
        }

        let scaledImage = outputImage.transformed(by: CGAffineTransform(scaleX: 10, y: 10))

        guard let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) else {
            return UIImage(systemName: "qrcode") ?? UIImage()
        }

        return UIImage(cgImage: cgImage)
    }
}

// MARK: - Analytics

struct AnalyticsView: View {
    @EnvironmentObject private var store: AppStore

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    HStack {
                        Text("Analytics")
                            .font(.largeTitle.bold())

                        Spacer()

                        Text("Last 6 Months")
                            .font(.caption.bold())
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(AppTheme.card)
                            .clipShape(Capsule())
                    }

                    LazyVGrid(columns: [.init(), .init()], spacing: 12) {
                        AnalyticsMetricCard(title: "ROI", value: store.roi.signedPercent)
                        AnalyticsMetricCard(title: "Win Rate", value: "\(Int(store.winRate))%")
                        AnalyticsMetricCard(title: "Total Profit", value: store.totalProfit.signedMoney)
                        AnalyticsMetricCard(title: "Avg Odds", value: String(format: "%.0f", store.averageOdds))
                    }

                    VStack(alignment: .leading, spacing: 14) {
                        Text("Bankroll Growth")
                            .font(.headline)

                        Chart(store.bankrollHistory()) { point in
                            LineMark(
                                x: .value("Date", point.title),
                                y: .value("Bankroll", point.value)
                            )

                            PointMark(
                                x: .value("Date", point.title),
                                y: .value("Bankroll", point.value)
                            )
                        }
                        .frame(height: 220)
                    }
                    .padding()
                    .background(AppTheme.card)
                    .clipShape(RoundedRectangle(cornerRadius: 18))

                    VStack(alignment: .leading, spacing: 14) {
                        Text("Performance by Sport")
                            .font(.headline)

                        Chart(store.performanceBySport()) { item in
                            BarMark(
                                x: .value("Win Rate", item.winRate),
                                y: .value("Sport", item.sport.rawValue)
                            )
                        }
                        .frame(height: 220)
                    }
                    .padding()
                    .background(AppTheme.card)
                    .clipShape(RoundedRectangle(cornerRadius: 18))

                    HStack {
                        AnalyticsInfoCard(
                            title: "Best Sport",
                            value: bestSportText,
                            subtitle: "Based on win rate",
                            icon: "trophy"
                        )

                        AnalyticsInfoCard(
                            title: "Needs Work",
                            value: worstSportText,
                            subtitle: "Lowest win rate",
                            icon: "chart.line.downtrend.xyaxis"
                        )
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Current Streak")
                            .foregroundColor(.gray)

                        Text("\(currentStreak)")
                            .font(.largeTitle.bold())

                        Text(currentStreak > 0 ? "Wins in a row! Keep it up!" : "No active win streak yet.")
                            .foregroundColor(AppTheme.green)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(AppTheme.green.opacity(0.16))
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                }
                .padding()
            }
            .background(AppTheme.background.ignoresSafeArea())
        }
    }

    private var bestSportText: String {
        store.performanceBySport()
            .filter { $0.total > 0 }
            .max { $0.winRate < $1.winRate }?
            .sport.rawValue ?? "-"
    }

    private var worstSportText: String {
        store.performanceBySport()
            .filter { $0.total > 0 }
            .min { $0.winRate < $1.winRate }?
            .sport.rawValue ?? "-"
    }

    private var currentStreak: Int {
        var streak = 0

        for booking in store.completedBookings {
            if booking.status == .won {
                streak += 1
            } else {
                break
            }
        }

        return streak
    }
}

struct AnalyticsMetricCard: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .foregroundColor(.gray)

            Text(value)
                .font(.title.bold())
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct AnalyticsInfoCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: icon)
                .foregroundColor(.gray)

            Text(value)
                .font(.headline.bold())

            Text(subtitle)
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Profile

struct ProfileView: View {
    @EnvironmentObject private var store: AppStore

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    Text("Profile")
                        .font(.largeTitle.bold())

                    HStack(spacing: 16) {
                        Image(systemName: "person")
                            .font(.largeTitle)
                            .padding()
                            .background(.white.opacity(0.16))
                            .clipShape(Circle())

                        VStack(alignment: .leading, spacing: 4) {
                            Text(store.profile.fullName)
                                .font(.title2.bold())

                            Text("@\(store.profile.username)")
                                .foregroundColor(.white.opacity(0.8))

                            Text("Pro Member")
                                .font(.caption.bold())
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(.white.opacity(0.16))
                                .clipShape(Capsule())
                        }

                        Spacer()
                    }
                    .padding()
                    .background(AppTheme.orange)
                    .clipShape(RoundedRectangle(cornerRadius: 20))

                    HStack {
                        ProfileStatView(title: "Total Bets", value: "\(store.bookings.count)")
                        ProfileStatView(title: "Wins", value: "\(store.completedBookings.filter { $0.status == .won }.count)")
                        ProfileStatView(title: "Win Rate", value: "\(Int(store.winRate))%")
                    }

                    SettingsSectionView(title: "Account") {
                        NavigationLink {
                            PersonalInformationView()
                        } label: {
                            SettingsRowView(icon: "person", title: "Personal Information", subtitle: "Update your profile details")
                        }

                        NavigationLink {
                            EmailSettingsView()
                        } label: {
                            SettingsRowView(icon: "envelope", title: "Email Settings", subtitle: store.profile.email)
                        }

                        NavigationLink {
                            PasswordSecurityView()
                        } label: {
                            SettingsRowView(icon: "lock", title: "Password & Security", subtitle: "Change password")
                        }
                    }

                    SettingsSectionView(title: "Preferences") {
                        HStack {
                            SettingsRowView(icon: "bell", title: "Notifications", subtitle: store.notificationsEnabled ? "Enabled" : "Disabled")

                            Toggle("", isOn: Binding(
                                get: { store.notificationsEnabled },
                                set: { store.setNotifications($0) }
                            ))
                            .labelsHidden()
                            .tint(AppTheme.orange)
                        }
                    }

                    SettingsSectionView(title: "Bankroll") {
                        NavigationLink {
                            BankrollSettingsView()
                        } label: {
                            SettingsRowView(icon: "dollarsign", title: "Bankroll Settings", subtitle: "Manage your bankroll")
                        }

                        NavigationLink {
                            BonusHubView()
                        } label: {
                            SettingsRowView(icon: "gift", title: "Bonus Hub", subtitle: "View your rewards")
                        }
                    }

                    Button(role: .destructive) {
                        store.logout()
                    } label: {
                        Label("Log Out", systemImage: "rectangle.portrait.and.arrow.right")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(AppTheme.red.opacity(0.18))
                            .foregroundColor(AppTheme.red)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }

                    Button {
                        store.clearCache()
                    } label: {
                        Text("Clear Cache")
                            .font(.subheadline.bold())
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(AppTheme.card)
                            .foregroundColor(.gray)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }

                    Text("MyBookie Plan v1.0.0\n18+ Virtual Planning Tool")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity)
                        .multilineTextAlignment(.center)
                        .padding(.top)
                }
                .padding()
            }
            .background(AppTheme.background.ignoresSafeArea())
        }
    }
}

struct ProfileStatView: View {
    let title: String
    let value: String

    var body: some View {
        VStack(spacing: 6) {
            Text(value)
                .font(.title2.bold())

            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(AppTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

struct PersonalInformationView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss

    @State private var fullName = ""
    @State private var username = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Personal Information")
                .font(.largeTitle.bold())

            VStack(spacing: 12) {
                Image(systemName: "person")
                    .font(.largeTitle)
                    .foregroundColor(.white)
                    .padding(34)
                    .background(AppTheme.orange)
                    .clipShape(Circle())

                Text("Upload Profile Photo")
                    .foregroundColor(.gray)
            }
            .frame(maxWidth: .infinity)

            AppTextField(title: "Full Name", placeholder: "John Doe", icon: "person", text: $fullName)
            AppTextField(title: "Username", placeholder: "johndoe", icon: "person", text: $username)

            Spacer()

            Button {
                store.profile.fullName = fullName.isEmpty ? store.profile.fullName : fullName
                store.profile.username = username.isEmpty ? store.profile.username : username
                dismiss()
            } label: {
                Text("Save Changes")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(AppTheme.orange)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
        }
        .padding()
        .background(AppTheme.background.ignoresSafeArea())
        .onAppear {
            fullName = store.profile.fullName
            username = store.profile.username
        }
    }
}

struct EmailSettingsView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss

    @State private var newEmail = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Email Settings")
                .font(.largeTitle.bold())

            Text("Important: Changing your email will require verification. A confirmation link will be sent to your new email address.")
                .padding()
                .background(AppTheme.orange.opacity(0.14))
                .clipShape(RoundedRectangle(cornerRadius: 14))

            AppStaticField(title: "Current Email", value: store.profile.email, icon: "envelope")

            AppTextField(
                title: "New Email",
                placeholder: "Enter your new email address",
                icon: "envelope",
                text: $newEmail
            )
            .keyboardType(.emailAddress)

            Spacer()

            Button {
                guard !newEmail.isEmpty else { return }
                store.profile.email = newEmail
                dismiss()
            } label: {
                Text("Update Email")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(AppTheme.orange)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
        }
        .padding()
        .background(AppTheme.background.ignoresSafeArea())
    }
}

struct PasswordSecurityView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var errorText = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Password & Security")
                .font(.largeTitle.bold())

            Text("Security tip: Use a strong password with at least 8 characters, including uppercase, lowercase, numbers, and special characters.")
                .padding()
                .background(AppTheme.orange.opacity(0.14))
                .clipShape(RoundedRectangle(cornerRadius: 14))

            AppTextField(title: "Current Password", placeholder: "Enter your current password", icon: "lock", text: $currentPassword)
            AppTextField(title: "New Password", placeholder: "Enter your new password", icon: "lock", text: $newPassword)
            AppTextField(title: "Confirm Password", placeholder: "Re-enter your new password", icon: "lock", text: $confirmPassword)

            if !errorText.isEmpty {
                Text(errorText)
                    .foregroundColor(AppTheme.red)
                    .font(.caption)
            }

            Spacer()

            Button {
                changePassword()
            } label: {
                Text("Change Password")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(AppTheme.orange)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
        }
        .padding()
        .background(AppTheme.background.ignoresSafeArea())
    }

    private func changePassword() {
        guard newPassword.count >= 8 else {
            errorText = "Password must contain at least 8 characters."
            return
        }

        guard newPassword == confirmPassword else {
            errorText = "Passwords do not match."
            return
        }

        dismiss()
    }
}

struct BankrollSettingsView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss

    @State private var bankrollText = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Bankroll Settings")
                .font(.largeTitle.bold())

            AppStaticField(
                title: "Current Starting Bankroll",
                value: store.profile.startingBankroll.money,
                icon: "dollarsign"
            )

            AppTextField(
                title: "New Starting Bankroll",
                placeholder: "e.g. 2500",
                icon: "dollarsign",
                text: $bankrollText
            )
            .keyboardType(.decimalPad)

            Spacer()

            Button {
                let value = Double(bankrollText.replacingOccurrences(of: ",", with: ".")) ?? store.profile.startingBankroll
                store.profile.startingBankroll = value
                dismiss()
            } label: {
                Text("Save Bankroll")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(AppTheme.orange)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
        }
        .padding()
        .background(AppTheme.background.ignoresSafeArea())
    }
}

// MARK: - Reusable UI

struct AppTextField: View {
    let title: String
    let placeholder: String
    let icon: String

    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: icon)
                .font(.caption.bold())
                .foregroundColor(.white)

            TextField(placeholder, text: $text)
                .padding()
                .background(AppTheme.field)
                .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }
}

struct AppStaticField: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: icon)
                .font(.caption.bold())
                .foregroundColor(.white)

            Text(value)
                .foregroundColor(.gray)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(AppTheme.card)
                .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }
}

struct FilterButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.bold())
                .padding(.horizontal, 18)
                .padding(.vertical, 12)
                .background(isSelected ? AppTheme.orange : AppTheme.card)
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }
}

struct SegmentButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.bold())
                .frame(maxWidth: .infinity)
                .padding()
                .background(isSelected ? AppTheme.orange : Color.clear)
                .foregroundColor(isSelected ? .white : .gray)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}

struct SettingsSectionView<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title.uppercased())
                .font(.caption.bold())
                .foregroundColor(.gray)

            VStack(spacing: 0) {
                content
            }
            .padding()
            .background(AppTheme.card)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }
}

struct SettingsRowView: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .foregroundColor(AppTheme.orange)
                .frame(width: 34, height: 34)
                .background(AppTheme.orange.opacity(0.15))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.subheadline.bold())
                    .foregroundColor(.white)

                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.gray)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption.bold())
                .foregroundColor(.gray)
        }
        .padding(.vertical, 8)
    }
}

struct DetailLine: View {
    let title: String
    let value: String

    var body: some View {
        HStack(alignment: .top) {
            Text(title)
                .foregroundColor(.gray)
                .frame(width: 130, alignment: .leading)

            Spacer()

            Text(value)
                .fontWeight(.semibold)
                .multilineTextAlignment(.trailing)
        }
        .font(.subheadline)
    }
}

// MARK: - Helpers

extension Date {
    static func demoDate(daysFromToday: Int, hour: Int, minute: Int = 0) -> Date {
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: Date())
        let date = calendar.date(byAdding: .day, value: daysFromToday, to: startOfToday) ?? Date()

        return calendar.date(
            bySettingHour: hour,
            minute: minute,
            second: 0,
            of: date
        ) ?? date
    }

    var shortMonthDay: String {
        formatted("MMM d")
    }

    var shortTime: String {
        formatted("HH:mm")
    }

    var weekdayShort: String {
        formatted("E")
    }

    var dayNumber: String {
        formatted("d")
    }

    var monthYear: String {
        formatted("MMMM yyyy")
    }

    private func formatted(_ format: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.string(from: self)
    }
}

extension Double {
    var money: String {
        "$" + String(format: "%.2f", self)
    }

    var signedMoney: String {
        let sign = self >= 0 ? "+" : "-"
        return sign + "$" + String(format: "%.2f", abs(self))
    }

    var signedPercent: String {
        let sign = self >= 0 ? "+" : "-"
        return sign + String(format: "%.1f", abs(self)) + "%"
    }
}

extension Int {
    var oddsText: String {
        self > 0 ? "+\(self)" : "\(self)"
    }
}