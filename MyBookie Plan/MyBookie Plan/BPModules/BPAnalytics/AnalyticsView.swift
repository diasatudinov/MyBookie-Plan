//
//  AnalyticsView.swift
//  MyBookie Plan
//
//

import SwiftUI
import Charts

// MARK: - Analytics

struct AnalyticsView: View {
    @EnvironmentObject private var store: AppStore

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    HStack {
                        Text("Analytics")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)

                        Spacer()

                        Text("Last 6 Months")
                            .font(.caption.bold())
                            .foregroundColor(.gray)
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
                            .foregroundColor(.white)

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
                        .chartXAxis {
                            AxisMarks { _ in
                                AxisGridLine()
                                    .foregroundStyle(Color.white.opacity(0.15))

                                AxisTick()
                                    .foregroundStyle(Color.white.opacity(0.4))

                                AxisValueLabel()
                                    .foregroundStyle(Color.white)
                            }
                        }
                        .chartYAxis {
                            AxisMarks { _ in
                                AxisGridLine()
                                    .foregroundStyle(Color.white.opacity(0.15))

                                AxisTick()
                                    .foregroundStyle(Color.white.opacity(0.4))

                                AxisValueLabel()
                                    .foregroundStyle(Color.white)
                            }
                        }
                        .frame(height: 220)
                        
                    }
                    .padding()
                    .foregroundStyle(AppTheme.orange)
                    .background(AppTheme.card)
                    .clipShape(RoundedRectangle(cornerRadius: 18))

                    VStack(alignment: .leading, spacing: 14) {
                        Text("Performance by Sport")
                            .font(.headline)
                            .foregroundColor(.white)

                        PerformanceDonutChartView(items: store.performanceBySport())
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
                            .foregroundStyle(Color.white)
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
                .foregroundColor(.white)
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
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(Color.white)
            Text(subtitle)
                .font(.caption)
                .foregroundColor(AppTheme.orange)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct PerformanceDonutChartView: View {
    let items: [SportPerformance]

    private var segments: [DonutSegment] {
        let colors: [Color] = [
            AppTheme.orange,
            .yellow,
            .cyan,
            .green,
            .gray
        ]

        return items.enumerated().map { index, item in
            DonutSegment(
                sport: item.sport,
                value: Double(max(item.wins, 0)),
                wins: item.wins,
                color: colors[index % colors.count]
            )
        }
    }

    private var visibleSegments: [DonutSegment] {
        let filtered = segments.filter { $0.value > 0 }

        if filtered.isEmpty {
            return [
                DonutSegment(
                    sport: .basketball,
                    value: 1,
                    wins: 0,
                    color: .gray
                )
            ]
        }

        return filtered
    }

    var body: some View {
        HStack(spacing: 24) {
            DonutChartView(segments: visibleSegments)
                .frame(width: 150, height: 150)

            VStack(alignment: .leading, spacing: 14) {
                ForEach(segments) { segment in
                    HStack(spacing: 10) {
                        Circle()
                            .fill(segment.color)
                            .frame(width: 12, height: 12)

                        Text(segment.sport.rawValue)
                            .foregroundColor(.white)
                            .lineLimit(1)

                        Spacer()

                        Text("\(segment.wins)W")
                            .fontWeight(.bold)
                            .foregroundColor(.gray)
                    }
                    .font(.subheadline)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct DonutChartView: View {
    let segments: [DonutSegment]

    private let lineWidth: CGFloat = 34

    private var total: Double {
        segments.reduce(0) { $0 + $1.value }
    }

    var body: some View {
        ZStack {
            ForEach(Array(segments.enumerated()), id: \.element.id) { index, segment in
                DonutArc(
                    startAngle: startAngle(for: index),
                    endAngle: endAngle(for: index),
                    lineWidth: lineWidth
                )
                .stroke(
                    segment.color,
                    style: StrokeStyle(
                        lineWidth: lineWidth,
                        lineCap: .butt,
                        lineJoin: .round
                    )
                )
            }

            Circle()
                .fill(AppTheme.card)
                .frame(width: 72, height: 72)
        }
    }

    private func startAngle(for index: Int) -> Angle {
        let previousValue = segments.prefix(index).reduce(0) { $0 + $1.value }
        let degrees = total == 0 ? 0 : previousValue / total * 360

        return .degrees(-90 + degrees)
    }

    private func endAngle(for index: Int) -> Angle {
        let currentValue = segments.prefix(index + 1).reduce(0) { $0 + $1.value }
        let degrees = total == 0 ? 0 : currentValue / total * 360

        return .degrees(-90 + degrees)
    }
}

struct DonutArc: Shape {
    let startAngle: Angle
    let endAngle: Angle
    let lineWidth: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()

        let radius = (min(rect.width, rect.height) - lineWidth) / 2
        let center = CGPoint(x: rect.midX, y: rect.midY)

        path.addArc(
            center: center,
            radius: radius,
            startAngle: startAngle,
            endAngle: endAngle,
            clockwise: false
        )

        return path
    }
}

struct DonutSegment: Identifiable {
    let id = UUID()
    let sport: Sport
    let value: Double
    let wins: Int
    let color: Color
}

#Preview {
    AnalyticsView()
        .environmentObject(AppStore())
}
