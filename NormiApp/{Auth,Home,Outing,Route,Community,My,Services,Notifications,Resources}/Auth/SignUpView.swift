// ============================================================
//  SignUpView.swift
// ============================================================

import SwiftUI

struct SignUpView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @Environment(\.dismiss) var dismiss

    @State private var nickname = ""
    @State private var email    = ""
    @State private var password = ""
    @State private var confirm  = ""
    @State private var agreedToTerms = false

    private var isValid: Bool {
        !nickname.isEmpty && !email.isEmpty &&
        password.count >= 6 && password == confirm && agreedToTerms
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "#F8F9FF").ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // Header
                        VStack(spacing: 6) {
                            Text("👋")
                                .font(.system(size: 48))
                            Text("처음 오셨나요?")
                                .font(.normiTitle2)
                                .foregroundColor(.normiNavy)
                            Text("간단하게 가입하고 소풍을 시작해요")
                                .font(.normiCaption)
                                .foregroundColor(.normiSubText)
                        }
                        .padding(.top, 20)

                        // Form
                        VStack(spacing: 14) {
                            normiField("별명 (닉네임)", icon: "person", text: $nickname,
                                       placeholder: "사용하실 이름을 입력해주세요")
                            normiField("이메일", icon: "envelope", text: $email,
                                       placeholder: "이메일 주소",
                                       keyboard: .emailAddress, autocap: .none)
                            normiSecureField("비밀번호 (6자 이상)", icon: "lock", text: $password,
                                             placeholder: "비밀번호")
                            normiSecureField("비밀번호 확인", icon: "lock.shield", text: $confirm,
                                             placeholder: "비밀번호 재입력")

                            if !confirm.isEmpty && password != confirm {
                                Label("비밀번호가 일치하지 않습니다", systemImage: "xmark.circle.fill")
                                    .font(.normiCaption)
                                    .foregroundColor(.normiRed)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }

                            // Terms
                            Toggle(isOn: $agreedToTerms) {
                                Text("이용약관 및 개인정보처리방침에 동의합니다")
                                    .font(.normiCaption)
                                    .foregroundColor(.normiText)
                            }
                            .tint(.normiBlue)

                            if let err = authVM.errorMessage {
                                Text(err)
                                    .font(.normiCaption)
                                    .foregroundColor(.normiRed)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(10)
                                    .background(Color.normiRed.opacity(0.08))
                                    .cornerRadius(8)
                            }

                            Button(action: {
                                Task { await authVM.signUp(email: email, password: password, nickname: nickname) }
                            }) {
                                HStack {
                                    if authVM.isLoading { ProgressView().tint(.white) }
                                    Text(authVM.isLoading ? "가입 중..." : "가입 완료")
                                }
                            }
                            .buttonStyle(NormiPrimaryButton())
                            .disabled(!isValid || authVM.isLoading)
                            .opacity(!isValid ? 0.5 : 1)
                        }
                        .normiCard(padding: 24, radius: 20)
                        .padding(.horizontal, 24)
                    }
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("회원가입")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("닫기") { dismiss() }
                }
            }
        }
    }

    // MARK: - Field Helpers

    private func normiField(_ label: String, icon: String, text: Binding<String>,
                             placeholder: String,
                             keyboard: UIKeyboardType = .default,
                             autocap: UITextAutocapitalizationType = .sentences) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(label, systemImage: icon)
                .font(.normiCaption.weight(.semibold))
                .foregroundColor(.normiSubText)
            TextField(placeholder, text: text)
                .keyboardType(keyboard)
                .autocapitalization(autocap)
                .padding(14)
                .background(Color.normiGray)
                .cornerRadius(12)
        }
    }

    private func normiSecureField(_ label: String, icon: String, text: Binding<String>,
                                   placeholder: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(label, systemImage: icon)
                .font(.normiCaption.weight(.semibold))
                .foregroundColor(.normiSubText)
            SecureField(placeholder, text: text)
                .padding(14)
                .background(Color.normiGray)
                .cornerRadius(12)
        }
    }
}
