// ============================================================
//  AuthViewModel.swift
// ============================================================

import Foundation
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import Combine

@MainActor
final class AuthViewModel: ObservableObject {
    @Published var currentUser: NormiUser?
    @Published var isLoggedIn    = false
    @Published var isLoading     = false
    @Published var errorMessage: String?

    private let auth    = Auth.auth()
    private let db      = Firestore.firestore()
    private var authListener: AuthStateDidChangeListenerHandle?

    init() {
        authListener = auth.addStateDidChangeListener { [weak self] _, user in
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
            var profile = NormiUser(
                id: nil,
                nickname: nickname,
                email: email,
                profileImageURL: nil,
                createdAt: Date()
            )
            profile.id = uid
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
        do {
            try auth.signOut()
            currentUser = nil
            isLoggedIn  = false
        } catch {
            errorMessage = "로그아웃에 실패했습니다."
        }
    }

    // MARK: - Delete Account (재인증 + 전체 데이터 삭제)

    func deleteAccount(password: String) async {
        isLoading = true
        errorMessage = nil
        do {
            guard let user = auth.currentUser,
                  let email = user.email else {
                errorMessage = "사용자 정보를 찾을 수 없습니다."
                isLoading = false
                return
            }

            // 1. 재인증
            let credential = EmailAuthProvider.credential(
                withEmail: email,
                password: password
            )
            try await user.reauthenticate(with: credential)

            let uid = user.uid

            // 2. 내 게시글 조회 후 삭제
            let postsSnap = try await db.collection("posts")
                .whereField("authorUID", isEqualTo: uid)
                .getDocuments()

            for postDoc in postsSnap.documents {
                let postID = postDoc.documentID

                // 2-1. 게시글의 댓글 삭제
                let commentsSnap = try await db.collection("posts")
                    .document(postID)
                    .collection("comments")
                    .getDocuments()
                for commentDoc in commentsSnap.documents {
                    try await commentDoc.reference.delete()
                }

                // 2-2. Firebase Storage 이미지 삭제
                if let imageURLs = postDoc.data()["imageURLs"] as? [String] {
                    for urlString in imageURLs {
                        if let url = URL(string: urlString) {
                            let path = url.path
                            let ref = Storage.storage().reference(withPath: path)
                            try? await ref.delete()
                        }
                    }
                }

                // 2-3. 게시글 삭제
                try await postDoc.reference.delete()
            }

            // 3. 다른 게시글에 달린 내 댓글 삭제
            let allPostsSnap = try await db.collection("posts").getDocuments()
            for postDoc in allPostsSnap.documents {
                let myCommentsSnap = try await db.collection("posts")
                    .document(postDoc.documentID)
                    .collection("comments")
                    .whereField("authorUID", isEqualTo: uid)
                    .getDocuments()
                for commentDoc in myCommentsSnap.documents {
                    try await commentDoc.reference.delete()
                }
            }

            // 4. 신고 데이터 삭제
            let reportsSnap = try await db.collection("reports")
                .whereField("reporterUID", isEqualTo: uid)
                .getDocuments()
            for reportDoc in reportsSnap.documents {
                try await reportDoc.reference.delete()
            }

            // 5. 유저 프로필 삭제
            try await db.collection("users").document(uid).delete()

            // 6. Firebase Auth 계정 삭제
            try await user.delete()

            currentUser = nil
            isLoggedIn  = false

        } catch let error as NSError {
            switch error.code {
            case AuthErrorCode.wrongPassword.rawValue:
                errorMessage = "비밀번호가 올바르지 않습니다."
            case AuthErrorCode.networkError.rawValue:
                errorMessage = "네트워크 연결을 확인해주세요."
            default:
                errorMessage = "회원 탈퇴에 실패했습니다: \(error.localizedDescription)"
            }
        }
        isLoading = false
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

    // MARK: - Error Messages

    private func authErrorMessage(_ error: Error) -> String {
        let code = (error as NSError).code
        switch code {
        case 17007: return "이미 사용 중인 이메일입니다."
        case 17008: return "올바른 이메일 형식이 아닙니다."
        case 17026: return "비밀번호는 6자 이상이어야 합니다."
        case 17009: return "비밀번호가 올바르지 않습니다."
        case 17011: return "등록되지 않은 이메일입니다."
        case 17020: return "네트워크 연결을 확인해주세요."
        default:    return "오류가 발생했습니다. 다시 시도해주세요."
        }
    }
}
