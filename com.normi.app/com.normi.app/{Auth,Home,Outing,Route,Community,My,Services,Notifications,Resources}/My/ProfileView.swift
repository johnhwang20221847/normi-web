import SwiftUI

struct ProfileView: View {
    let userUID: String
    let nickname: String
    let isMyProfile: Bool

    @EnvironmentObject var authVM: AuthViewModel
    @StateObject private var postVM   = PostViewModel()
    @StateObject private var reportVM = ReportBlockViewModel()

    @State private var showBlockSheet  = false
    @State private var showReportSheet = false
    @State private var showDeleteAlert = false
    @State private var reauthPassword = ""

    // ✅ 내가 쓴 게시글만 필터링
    private var myPosts: [CommunityPost] {
        postVM.posts.filter { $0.authorUID == userUID }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {

                // ─── 프로필 헤더 ───────────────────────────────
                VStack(spacing: 16) {
                    Circle()
                        .fill(LinearGradient(
                            colors: [.blue.opacity(0.6), .purple.opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 88, height: 88)
                        .overlay(
                            Text(String(nickname.prefix(1)))
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        )

                    Text(nickname)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)

                    // 타인 프로필 — 신고/차단
                    if !isMyProfile {
                        HStack(spacing: 12) {
                            Button { showReportSheet = true } label: {
                                Label("신고", systemImage: "exclamationmark.triangle")
                                    .font(.subheadline).fontWeight(.medium)
                                    .foregroundColor(.orange)
                                    .padding(.horizontal, 20).padding(.vertical, 10)
                                    .background(Color.orange.opacity(0.1))
                                    .cornerRadius(22)
                                    .overlay(RoundedRectangle(cornerRadius: 22)
                                        .stroke(Color.orange.opacity(0.3), lineWidth: 1))
                            }
                            Button { showBlockSheet = true } label: {
                                Label(
                                    reportVM.isBlocked(userUID) ? "차단됨" : "차단",
                                    systemImage: reportVM.isBlocked(userUID)
                                        ? "person.crop.circle.badge.checkmark"
                                        : "person.crop.circle.badge.xmark"
                                )
                                .font(.subheadline).fontWeight(.medium)
                                .foregroundColor(reportVM.isBlocked(userUID) ? .green : .red)
                                .padding(.horizontal, 20).padding(.vertical, 10)
                                .background((reportVM.isBlocked(userUID) ? Color.green : Color.red).opacity(0.1))
                                .cornerRadius(22)
                                .overlay(RoundedRectangle(cornerRadius: 22)
                                    .stroke((reportVM.isBlocked(userUID) ? Color.green : Color.red).opacity(0.3), lineWidth: 1))
                            }
                        }
                    }

                    // 내 프로필 — 로그아웃/탈퇴
                    if isMyProfile {
                        VStack(spacing: 10) {
                            Button { authVM.signOut() } label: {
                                Label("로그아웃", systemImage: "rectangle.portrait.and.arrow.right")
                                    .font(.subheadline).fontWeight(.medium)
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal, 20).padding(.vertical, 10)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(22)
                            }
                            Button { showDeleteAlert = true } label: {
                                Label("회원 탈퇴", systemImage: "person.crop.circle.badge.minus")
                                    .font(.subheadline).fontWeight(.medium)
                                    .foregroundColor(.red)
                                    .padding(.horizontal, 20).padding(.vertical, 10)
                                    .background(Color.red.opacity(0.1))
                                    .cornerRadius(22)
                                    .overlay(RoundedRectangle(cornerRadius: 22)
                                        .stroke(Color.red.opacity(0.3), lineWidth: 1))
                            }
                        }
                    }
                }
                .padding(.vertical, 32)
                .frame(maxWidth: .infinity)
                .background(Color(.systemGroupedBackground))

                // ─── 작성한 게시글 ✅ 실제 데이터로 교체 ─────
                VStack(alignment: .leading, spacing: 0) {
                    Text("작성한 게시글")
                        .font(.headline)
                        .foregroundColor(.primary)
                        .padding(.horizontal, 20)
                        .padding(.top, 24)
                        .padding(.bottom, 12)

                    if postVM.isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                    } else if myPosts.isEmpty {
                        Text("작성한 게시글이 없습니다.")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                    } else {
                        LazyVStack(spacing: 12) {
                            ForEach(myPosts) { post in
                                NavigationLink(destination:
                                    PostDetailView(post: post)
                                        .environmentObject(authVM)
                                ) {
                                    PostCardView(post: post)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 20)
                    }
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if !isMyProfile {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button(role: .destructive) { showReportSheet = true } label: {
                            Label("신고하기", systemImage: "exclamationmark.triangle")
                        }
                        Button(role: .destructive) { showBlockSheet = true } label: {
                            Label(
                                reportVM.isBlocked(userUID) ? "차단 해제" : "차단하기",
                                systemImage: "person.crop.circle.badge.xmark"
                            )
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle").font(.body)
                    }
                }
            }
        }
        .task {
            await reportVM.loadBlockedUsers()
            postVM.startListening()     // ✅ 전체 게시글 로드 후 myPosts로 필터링
        }
        .onDisappear {
            postVM.stopListening()
        }
        .alert("회원 탈퇴", isPresented: $showDeleteAlert) {
            SecureField("비밀번호 입력", text: $reauthPassword)
            Button("탈퇴하기", role: .destructive) {
                Task {
                    await authVM.deleteAccount(password: reauthPassword)
                    reauthPassword = ""
                }
            }
            Button("취소", role: .cancel) {
                reauthPassword = ""
            }
        } message: {
            Text("본인 확인을 위해 비밀번호를 입력해주세요.\n탈퇴 시 모든 데이터가 삭제되며 복구할 수 없습니다.")
        }
        .sheet(isPresented: $showBlockSheet) {
            BlockUserView(targetUID: userUID, targetNickname: nickname)
                .presentationDetents([.medium])
                .onDisappear { Task { await reportVM.loadBlockedUsers() } }
        }
        .sheet(isPresented: $showReportSheet) {
            ReportSheetView(targetType: .user, targetID: userUID, targetName: nickname)
        }
    }
}

#Preview {
    NavigationStack {
        ProfileView(userUID: "sampleUID", nickname: "달리기왕", isMyProfile: false)
            .environmentObject(AuthViewModel())
    }
}
