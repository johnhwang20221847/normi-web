// ============================================================
//  AuthViewModel.swift
//  Firebase Auth 기반 로그인 / 회원가입 / 로그아웃
// ============================================================

import Foundation
import FirebaseAuth
import FirebaseFirestore

@MainActor
final class AuthViewModel: ObservableObject {
    @Published var currentUser: NormiUser?
    @Published var isLoggedIn = false
    @Published var isLoading  = false
    @Published var errorMessage: String?

    private let auth = Auth.auth()
    private let db   = Firestore.firestore()

    init() {
        // 자동 로그인 감지
        auth.addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in
                if let user {
                    await self?.fetchUserProfile(uid: user.uid)
                    self?.isLoggedIn = true
                } else {
                    self?.currentUser = nil
                    self?.isLoggedIn  = false
                }
            }
        }
    }

    // MARK: - Sign Up

    func signUp(email: String, password: String, nickname: String) async {
        isLoading = true
        errorMessage = nil
        do {
            let result = try await auth.createUser(withEmail: email, password: password)
            let uid = result.user.uid

            let profile = NormiUser(
                id: uid,
                nickname: nickname,
                email: email,
                profileImageURL: nil,
                createdAt: Date()
            )
            try db.collection("users").document(uid).setData(from: profile)
            currentUser = profile
            isLoggedIn  = true
        } catch {
            errorMessage = authErrorMessage(error)
        }
        isLoading = false
    }

    // MARK: - Sign In

    func signIn(email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        do {
            let result = try await auth.signIn(withEmail: email, password: password)
            await fetchUserProfile(uid: result.user.uid)
            isLoggedIn = true
        } catch {
            errorMessage = authErrorMessage(error)
        }
        isLoading = false
    }

    // MARK: - Sign Out

    func signOut() {
        try? auth.signOut()
        currentUser = nil
        isLoggedIn  = false
    }

    // MARK: - Fetch Profile

    func fetchUserProfile(uid: String) async {
        do {
            let snap = try await db.collection("users").document(uid).getDocument()
            currentUser = try snap.data(as: NormiUser.self)
        } catch {
            print("프로필 로드 실패: \(error)")
        }
    }

    // MARK: - Error Messages (Korean)

    private func authErrorMessage(_ error: Error) -> String {
        let code = AuthErrorCode(_bridged: error as NSError)
        switch code.code {
        case .emailAlreadyInUse:     return "이미 사용 중인 이메일입니다."
        case .invalidEmail:          return "올바른 이메일 형식이 아닙니다."
        case .weakPassword:          return "비밀번호는 6자 이상이어야 합니다."
        case .wrongPassword:         return "비밀번호가 올바르지 않습니다."
        case .userNotFound:          return "등록되지 않은 이메일입니다."
        case .networkError:          return "네트워크 연결을 확인해주세요."
        default:                     return "오류가 발생했습니다. 다시 시도해주세요."
        }
    }
}
