//
//  AuthenticationView.swift
//  MyBookie Plan
//
//

import SwiftUI

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
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(.white)

                    Text("Bookie")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(AppTheme.orange)
                }

                VStack(spacing: 8) {
                    Text("Welcome back")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)

                    Text("Sign in to continue planning your sports\nstrategy")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(AppTheme.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.bottom, 6)

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
                            ZStack {
                                
                                if isPasswordVisible {
                                    TextField("", text: $password)
                                        .foregroundColor(.white)
                                } else {
                                    SecureField("", text: $password)
                                        .foregroundColor(.white)
                                }
                                
                                if password.isEmpty {
                                    HStack {
                                        Image(systemName: "lock")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(height: 14)
                                        
                                        Text("Enter your password")
                                            .font(.system(size: 16, weight: .regular))
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                        
                                    }
                                    .foregroundColor(.white.opacity(0.5))
                                    .allowsHitTesting(false)
                                }
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
                        .font(.system(size: 16, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(AppTheme.orange)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .padding(.top, 30)

                Text("18+ Virtual Planning Tool. Not a Gambling Product.")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(.gray)

                Spacer()
            }
            .padding(24)
        }
    }
}

#Preview {
    AuthenticationView()
        .environmentObject(AppStore())
}
