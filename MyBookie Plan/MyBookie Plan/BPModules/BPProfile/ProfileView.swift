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
