import SwiftUI

// MARK: - SignUpView (약관 동의 통합 버전)
// 기존 SignUpView를 이 코드로 교체하세요

struct SignUpView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) var dismiss

    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var nickname = ""

    // 약관 동의 상태
    @State private var showTermsSheet = false
    @State private var hasAgreedToTerms = false

    private var isFormValid: Bool {
        !email.isEmpty &&
        !password.isEmpty &&
        !nickname.isEmpty &&
        password == confirmPassword &&
        password.count >= 6 &&
        hasAgreedToTerms
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {

                    // 로고 영역
                    VStack(spacing: 8) {
                        Image(systemName: "figure.walk.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)
                        Text("노르미 가입")
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                    .padding(.top, 32)

                    // 입력 필드들
                    VStack(spacing: 14) {
                        SignUpTextField(
                            icon: "envelope",
                            placeholder: "이메일",
                            text: $email
                        )
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)

                        SignUpTextField(
                            icon: "person",
                            placeholder: "닉네임",
                            text: $nickname
                        )

                        SignUpSecureField(
                            icon: "lock",
                            placeholder: "비밀번호 (6자 이상)",
                            text: $password
                        )

                        SignUpSecureField(
                            icon: "lock.rotation",
                            placeholder: "비밀번호 확인",
                            text: $confirmPassword
                        )

                        if !confirmPassword.isEmpty && password != confirmPassword {
                            Text("비밀번호가 일치하지 않습니다.")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }

                    // ✅ 약관 동의 버튼 (Apple 필수 요구사항)
                    Button {
                        showTermsSheet = true
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: hasAgreedToTerms
                                  ? "checkmark.circle.fill"
                                  : "circle")
                                .font(.title3)
                                .foregroundColor(hasAgreedToTerms ? .blue : .gray)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(hasAgreedToTerms
                                     ? "이용약관에 동의했습니다"
                                     : "이용약관 동의 (필수)")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.primary)
                                Text("서비스 이용약관 · 개인정보처리방침 · 커뮤니티 가이드라인")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(16)
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(
                                    hasAgreedToTerms ? Color.blue.opacity(0.4) : Color.clear,
                                    lineWidth: 1.5
                                )
                        )
                    }

                    // 에러 메시지
                    if let error = authViewModel.errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                    }

                    // 가입 버튼
                    Button {
                        Task {
                            await authViewModel.signUp(
                                email: email,
                                password: password,
                                nickname: nickname
                            )
                        }
                    } label: {
                        Group {
                            if authViewModel.isLoading {
                                ProgressView()
                                    .progressViewStyle(.circular)
                                    .tint(.white)
                            } else {
                                Text("가입하기")
                                    .font(.body)
                                    .fontWeight(.semibold)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .foregroundColor(.white)
                        .background(isFormValid ? Color.blue : Color.gray)
                        .cornerRadius(14)
                    }
                    .disabled(!isFormValid || authViewModel.isLoading)

                    // 로그인 이동
                    Button {
                        dismiss()
                    } label: {
                        HStack(spacing: 4) {
                            Text("이미 계정이 있으신가요?")
                                .foregroundColor(.secondary)
                            Text("로그인")
                                .foregroundColor(.blue)
                                .fontWeight(.medium)
                        }
                        .font(.subheadline)
                    }
                    .padding(.bottom, 40)
                }
                .padding(.horizontal, 20)
            }
            .navigationBarHidden(true)
        }
        // ✅ 약관 동의 시트 (Apple 필수)
        .sheet(isPresented: $showTermsSheet) {
            TermsAgreementView(isPresented: $showTermsSheet) {
                hasAgreedToTerms = true
            }
        }
    }
}

// MARK: - 재사용 컴포넌트
struct SignUpTextField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.secondary)
                .frame(width: 20)
            TextField(placeholder, text: $text)
                .font(.body)
        }
        .padding(16)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct SignUpSecureField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.secondary)
                .frame(width: 20)
            SecureField(placeholder, text: $text)
                .font(.body)
        }
        .padding(16)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

#Preview {
    SignUpView()
        .environmentObject(AuthViewModel())
}
