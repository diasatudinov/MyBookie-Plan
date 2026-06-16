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