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