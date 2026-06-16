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