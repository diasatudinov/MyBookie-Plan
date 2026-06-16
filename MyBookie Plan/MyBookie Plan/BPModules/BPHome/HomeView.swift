//
//  HomeView.swift
//  MyBookie Plan
//
//

import SwiftUI

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
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)

                        Text("Ready to plan your next win?")
                            .font(.system(size: 16, weight: .regular))
                            .foregroundColor(.gray)
                    }

                    BankrollSummaryView()

                    if let next = store.nextBooking {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Next Booked Event")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.white)

                                Spacer()

                                Button {
                                    selectedTab = .bookings
                                } label: {
                                    Text("View All")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(AppTheme.orange)
                                }
                                
                            }

                            BookingCardView(booking: next)
                        }
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Quick Actions")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)

                        LazyVGrid(columns: [.init(), .init()], spacing: 12) {
                            QuickActionButton(title: "Book Event", icon: "plus") {
                                selectedTab = .bookings
                            }
                            .padding(.trailing, 4)

                            QuickActionButton(title: "View Calendar", icon: "calendar") {
                                selectedTab = .calendar
                            }
                            .padding(.leading, 4)

                            QuickActionButton(title: "Analytics", icon: "chart.line.uptrend.xyaxis") {
                                selectedTab = .analytics
                            }
                            .padding(.trailing, 4)

                            QuickActionButton(title: "Rewards", icon: "gift") {
                                selectedTab = .profile
                            }
                            .padding(.leading, 4)
                        }
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Recent Activity")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)

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
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(.white.opacity(0.8))

                    Text(store.bankroll.money)
                        .font(.system(size: 30, weight: .bold))
                        .foregroundColor(.white)
                }

                Spacer()

                Image(systemName: "dollarsign")
                    .font(.title2)
                    .foregroundColor(.white)
                    .padding()
                    .background(.white.opacity(0.18))
                    .clipShape(Circle())
            }

            HStack {
                SmallMetricView(title: "Monthly Profit", value: store.totalProfit.signedMoney)
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
                .font(.system(size: 12, weight: .regular))
                .foregroundColor(.white.opacity(0.8))

            Text(value)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
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
                    .font(.system(size: 14, weight: .semibold))
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
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)

                Text(booking.date.shortMonthDay)
                    .font(.system(size: 12, weight: .regular))
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
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(AppTheme.orange)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(AppTheme.orange.opacity(0.18))
                    .clipShape(Capsule())

                Text(booking.tournament)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(.gray)

                Text(booking.status.rawValue)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(borderColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(borderColor.opacity(0.14))
                    .clipShape(Capsule())

                Spacer()
                
                VStack(alignment: .trailing) {
                    Text(booking.odds.oddsText)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(AppTheme.orange)

                    Text("odds")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(.gray)
                }
                
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(booking.title)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                
                Text(booking.note)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.gray)
            }
            Divider()
                .background(.gray.opacity(0.4))

            HStack {
                HStack {
                    Label(booking.date.shortMonthDay, systemImage: "calendar")
                    Label(booking.date.shortTime, systemImage: "clock")
                }
                .font(.caption)
                .foregroundColor(.gray)
                Spacer()

                VStack(alignment: .trailing) {
                    Text(booking.stake.money)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("bankroll")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(.gray)
                }
            }
            

            HStack {

                if booking.status != .pending {
                    VStack(alignment: .leading) {
                        Text("Profit / Loss")
                            .font(.caption)
                            .foregroundColor(.gray)

                        Text(booking.bankrollDelta.signedMoney)
                            .font(.headline.bold())
                            .foregroundColor(booking.bankrollDelta >= 0 ? AppTheme.green : AppTheme.red)
                    }
                }
                Spacer()
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

#Preview {
    HomeView(selectedTab: .constant(.home))
        .environmentObject(AppStore())
}
