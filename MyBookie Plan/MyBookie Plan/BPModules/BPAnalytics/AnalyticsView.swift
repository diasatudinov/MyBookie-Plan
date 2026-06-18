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