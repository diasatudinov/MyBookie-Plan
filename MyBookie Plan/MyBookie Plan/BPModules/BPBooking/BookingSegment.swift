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