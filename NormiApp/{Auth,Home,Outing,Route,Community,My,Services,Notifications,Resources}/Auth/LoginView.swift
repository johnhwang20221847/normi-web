// ============================================================
//  LoginView.swift
//  화면 2 — 로그인 / 회원가입
// ============================================================

import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @State private var email    = ""
    @State private var password = ""
    @State private var showSignUp = false

    var body: some View {
        NavigationView {
            ZStack {
                // Background
                LinearGradient(
                    colors: [Color(hex: "#EAF1FF"), Color(hex: "#F8F9FF")],
                    startPoint: .top, endPoint: .bottom
                )
                .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        // Logo & Welcome
                        logoSection
                            .padding(.top, 60)
                            .padding(.bottom, 40)

                        // Login Form
                        loginForm
                            .padding(.horizontal, 28)

                        // Sign Up Link
                        signUpLink
                            .padding(.top, 24)
                    }
                }
            }
        }
        .sheet(isPresented: $showSignUp) {
            SignUpView()
                .environmentObject(authVM)
        }
    }

    // MARK: - Logo

    private var logoSection: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.normiBlue.opacity(0.12))
                    .frame(width: 90, height: 90)
                Text("🚊")
                    .font(.system(size: 46))
            }
            Text("노르미")
                .font(.normiLargeTitle)
                .foregroundColor(.normiNavy)
            Text("어르신의 지하철 소풍을 함께해요")
                .font(.normiBody)
                .foregroundColor(.normiSubText)
        }
    }

    // MARK: - Login Form

    private var loginForm: some View {
        VStack(spacing: 16) {
            // Email
            VStack(alignment: .leading, spacing: 6) {
                Label("이메일", systemImage: "envelope")
                    .font(.normiCaption.weight(.semibold))
                    .foregroundColor(.normiSubText)
                TextField("이메일을 입력해주세요", text: $email)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .padding(14)
                    .background(Color.white)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.normiBlue.opacity(0.2), lineWidth: 1)
                    )
            }

            // Password
            VStack(alignment: .leading, spacing: 6) {
                Label("비밀번호", systemImage: "lock")
                    .font(.normiCaption.weight(.semibold))
                    .foregroundColor(.normiSubText)
                SecureField("비밀번호를 입력해주세요", text: $password)
                    .padding(14)
                    .background(Color.white)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.normiBlue.opacity(0.2), lineWidth: 1)
                    )
            }

            // Error
            if let err = authVM.errorMessage {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.normiRed)
                    Text(err)
                        .font(.normiCaption)
                        .foregroundColor(.normiRed)
                }
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.normiRed.opacity(0.08))
                .cornerRadius(10)
            }

            // Login Button
            Button(action: {
                Task { await authVM.signIn(email: email, password: password) }
            }) {
                HStack(spacing: 8) {
                    if authVM.isLoading {
                        ProgressView().tint(.white)
                    }
                    Text(authVM.isLoading ? "로그인 중..." : "로그인")
                }
            }
            .buttonStyle(NormiPrimaryButton())
            .disabled(authVM.isLoading || email.isEmpty || password.isEmpty)
            .padding(.top, 8)
        }
        .normiCard(padding: 24, radius: 20)
    }

    // MARK: - Sign Up Link

    private var signUpLink: some View {
        HStack(spacing: 4) {
            Text("아직 계정이 없으신가요?")
                .font(.normiCaption)
                .foregroundColor(.normiSubText)
            Button("회원가입") { showSignUp = true }
                .font(.normiCaption.weight(.semibold))
                .foregroundColor(.normiBlue)
        }
    }
}
