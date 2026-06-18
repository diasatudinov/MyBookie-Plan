//
//  MyBookiePlanApp.swift
//  MyBookie Plan
//
//


import SwiftUI
import Charts
import CoreImage.CIFilterBuiltins
import UIKit
import UserNotifications



// MARK: - Theme

enum AppTheme {
    static let background = Color(red: 0.04, green: 0.04, blue: 0.05)
    static let card = Color(red: 0.10, green: 0.10, blue: 0.11)
    static let field = Color(red: 0.14, green: 0.14, blue: 0.15)
    static let orange = Color.appOrange
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
    
    private struct DemoAccount {
        let fullName: String
        let username: String
        let email: String
        let password: String
    }

    private let demoAccounts: [DemoAccount] = [
        DemoAccount(
            fullName: "Review User",
            username: "reviewer",
            email: "reviewer@test.local",
            password: "review2026"
        ),
        DemoAccount(
            fullName: "John Doe",
            username: "johndoe",
            email: "john@test.local",
            password: "test1234"
        )
    ]
    
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

    let sportsEvents: [SportsEvent] = []
    let rewards: [Reward] = []

    init() {
        isLoggedIn = UserDefaults.standard.bool(forKey: Keys.isLoggedIn)
        profile = load(UserProfile.self, key: Keys.profile) ?? UserProfile()
        bookings = load([Booking].self, key: Keys.bookings) ?? []
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

    func signIn(login: String, password: String) -> Bool {
        let cleanLogin = login
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()

        let cleanPassword = password
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard let account = demoAccounts.first(where: { account in
            account.email.lowercased() == cleanLogin ||
            account.username.lowercased() == cleanLogin
        }) else {
            return false
        }

        guard account.password == cleanPassword else {
            return false
        }

        profile.fullName = account.fullName
        profile.username = account.username
        profile.email = account.email

        isLoggedIn = true
        return true
    }

    func logout() {
        isLoggedIn = false
    }

    func clearCache() {
        bookings = []
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

// MARK: - Reusable UI

struct AppTextField: View {
    let title: String
    let placeholder: String
    let icon: String

    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white)

            ZStack {
                TextField("", text: $text)
                    .foregroundColor(.white)
                    .padding()
                    .background(AppTheme.field)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                
                if text.isEmpty {
                    HStack {
                        Image(systemName: icon)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 14)
                        
                        Text(placeholder)
                            .font(.system(size: 16, weight: .regular))
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                    }
                    .padding(.leading)
                    .foregroundColor(.white.opacity(0.5))
                    .allowsHitTesting(false)
                }
            }
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
                .foregroundColor(isSelected ? .white : .gray)
                .clipShape(RoundedRectangle(cornerRadius: 14))
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
                .foregroundColor(.white)
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
