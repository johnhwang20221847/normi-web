// ============================================================
//  ProfileView.swift
//  화면 9 — 마이탭: 내 정보 / 오늘도 수고하셨어요 / 로그아웃
//  와이어프레임: "내일도 좋은 날이 될 거에요. 안전하게 귀가하세요 😊"
//              "내일 알림 받기" / "로그아웃"
// ============================================================

import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @StateObject private var postsVM = PostViewModel()
    @State private var showLogoutAlert  = false
    @State private var showDeleteAlert  = false
    @State private var showEditProfile  = false
    @State private var myPosts: [CommunityPost] = []

    var body: some View {
        NavigationView {
            ZStack {
                Color.normiGray.ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        profileHeader
                        statsRow
                        farewell          // 와이어프레임 화면9 핵심 메시지
                        myPostsSection
                        settingsSection
                        logoutButton
                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                }
            }
            .navigationTitle("마이")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showEditProfile = true }) {
                        Image(systemName: "pencil.circle")
                            .foregroundColor(.normiBlue)
                    }
                }
            }
            .sheet(isPresented: $showEditProfile) {
                if let user = authVM.currentUser {
                    EditProfileView(user: user, authVM: authVM)
                }
            }
            .alert("로그아웃", isPresented: $showLogoutAlert) {
                Button("로그아웃", role: .destructive) { authVM.signOut() }
                Button("취소", role: .cancel) {}
            } message: {
                Text("정말 로그아웃 하시겠어요?")
            }
        }
        .task { await loadMyPosts() }
    }

    // MARK: - 프로필 헤더

    private var profileHeader: some View {
        HStack(spacing: 16) {
            // 아바타
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(colors: [Color.normiBlue, Color(hex: "#74B3FF")],
                                       startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .frame(width: 72, height: 72)
                Text(String(authVM.currentUser?.nickname.prefix(1) ?? "N"))
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(authVM.currentUser?.nickname ?? "노르미 사용자")
                    .font(.normiTitle2)
                    .foregroundColor(.normiNavy)
                Text(authVM.currentUser?.email ?? "")
                    .font(.normiCaption)
                    .foregroundColor(.normiSubText)
                NormiBadge(text: "소풍 단골", color: .normiOrange)
            }
            Spacer()
        }
        .normiCard()
    }

    // MARK: - 통계

    private var statsRow: some View {
        HStack(spacing: 0) {
            statItem(value: "\(myPosts.count)", label: "소풍 기록")
            Divider().frame(height: 44)
            statItem(value: "\(myPosts.reduce(0) { $0 + $1.likes })", label: "받은 좋아요")
            Divider().frame(height: 44)
            statItem(value: "\(myPosts.reduce(0) { $0 + $1.commentCount })", label: "달린 댓글")
        }
        .padding(.vertical, 14)
        .normiCard(padding: 0)
    }

    private func statItem(_ : Void = (), value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.normiTitle2)
                .foregroundColor(.normiNavy)
            Text(label)
                .font(.normiCaption2)
                .foregroundColor(.normiSubText)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - 화면9 작별 인사 카드

    private var farewell: some View {
        VStack(spacing: 16) {
            // 달 + 별 배경 (와이어프레임 화면9)
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "#0D1B3E"), Color(hex: "#1B3A6B")],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )
                    )
                // 별 장식
                ForEach(0..<12, id: \.self) { i in
                    Circle()
                        .fill(Color.white.opacity(Double.random(in: 0.3...0.9)))
                        .frame(width: CGFloat.random(in: 2...5),
                               height: CGFloat.random(in: 2...5))
                        .offset(
                            x: CGFloat.random(in: -130...130),
                            y: CGFloat.random(in: -50...30)
                        )
                }
                VStack(spacing: 10) {
                    Text("🌙")
                        .font(.system(size: 48))
                    Text("오늘도 수고하셨어요!")
                        .font(.normiTitle2)
                        .foregroundColor(.white)
                    Text("내일도 좋은 날이 될 거에요.\n안전하게 귀가하세요 😊")
                        .font(.normiBody)
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }
                .padding(.vertical, 30)
            }
            .frame(height: 220)

            // 내일 알림 받기 버튼 (와이어프레임 화면9)
            Button(action: {
                NotificationManager.shared.scheduleTomorrowReminder()
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "bell.fill")
                    Text("내일 알림 받기")
                }
            }
            .buttonStyle(NormiPrimaryButton())
        }
    }

    // MARK: - 내 소풍 기록

    @ViewBuilder
    private var myPostsSection: some View {
        if !myPosts.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text("내 소풍 기록")
                    .font(.normiHeadline)
                    .foregroundColor(.normiNavy)

                ForEach(myPosts.prefix(3)) { post in
                    NavigationLink(destination: PostDetailView(post: post, vm: postsVM)) {
                        HStack(spacing: 12) {
                            // 썸네일
                            if let url = post.imageURLs.first {
                                AsyncImage(url: URL(string: url)) { img in
                                    img.resizable().scaledToFill()
                                } placeholder: { Color.normiGray }
                                .frame(width: 56, height: 56)
                                .clipped()
                                .cornerRadius(10)
                            } else {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 10).fill(Color.normiSky)
                                        .frame(width: 56, height: 56)
                                    Image(systemName: "photo").foregroundColor(.normiBlue)
                                }
                            }
                            VStack(alignment: .leading, spacing: 4) {
                                Text(post.content)
                                    .font(.normiCaption.weight(.semibold))
                                    .foregroundColor(.normiText)
                                    .lineLimit(2)
                                HStack(spacing: 8) {
                                    if let st = post.station {
                                        Label(st, systemImage: "tram")
                                            .font(.normiCaption2)
                                            .foregroundColor(.normiBlue)
                                    }
                                    Text(post.timeAgoText)
                                        .font(.normiCaption2)
                                        .foregroundColor(.normiSubText)
                                }
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.normiSubText)
                        }
                        .normiCard(padding: 12)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }

    // MARK: - 설정 섹션

    private var settingsSection: some View {
        VStack(spacing: 0) {
            settingsRow(icon: "bell.fill",      color: .normiBlue,   title: "알림 설정",       action: {})
            Divider().padding(.leading, 52)
            settingsRow(icon: "lock.fill",      color: .normiNavy,   title: "개인정보 보호",    action: {})
            Divider().padding(.leading, 52)
            settingsRow(icon: "questionmark.circle.fill", color: .normiGreen, title: "도움말", action: {})
            Divider().padding(.leading, 52)
            settingsRow(icon: "star.fill",      color: .normiOrange, title: "앱 평가하기",      action: rateApp)
            Divider().padding(.leading, 52)
            settingsRow(icon: "info.circle.fill", color: .normiSubText, title: "버전 정보  v1.0.0", action: {})
        }
        .normiCard(padding: 0)
    }

    private func settingsRow(icon: String, color: Color, title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8).fill(color.opacity(0.12))
                        .frame(width: 34, height: 34)
                    Image(systemName: icon).foregroundColor(color).font(.subheadline)
                }
                Text(title).font(.normiBody).foregroundColor(.normiText)
                Spacer()
                Image(systemName: "chevron.right").font(.caption).foregroundColor(.normiSubText)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
    }

    // MARK: - 로그아웃 버튼

    private var logoutButton: some View {
        Button(action: { showLogoutAlert = true }) {
            HStack {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                Text("로그아웃")
            }
            .font(.normiHeadline)
            .foregroundColor(.normiRed)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.normiRed.opacity(0.08))
            .cornerRadius(14)
        }
    }

    // MARK: - Helpers

    private func loadMyPosts() async {
        guard let uid = authVM.currentUser?.id else { return }
        // Firestore에서 내 글만 필터
        let db = Firestore.firestore()
        do {
            let snap = try await db.collection("posts")
                .whereField("authorUID", isEqualTo: uid)
                .order(by: "createdAt", descending: true)
                .getDocuments()
            myPosts = snap.documents.compactMap { try? $0.data(as: CommunityPost.self) }
        } catch {
            print("내 글 로드 오류: \(error)")
        }
    }

    private func rateApp() {
        guard let url = URL(string: "itms-apps://itunes.apple.com/app/idYOUR_APP_ID") else { return }
        UIApplication.shared.open(url)
    }
}

// MARK: - Edit Profile Sheet

struct EditProfileView: View {
    let user: NormiUser
    @ObservedObject var authVM: AuthViewModel
    @Environment(\.dismiss) var dismiss
    @State private var nickname = ""
    @State private var isSaving = false

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // 아바타 (향후 이미지 업로드 확장)
                ZStack {
                    Circle()
                        .fill(LinearGradient(colors: [.normiBlue, Color(hex:"#74B3FF")],
                                             startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 90, height: 90)
                    Text(String(nickname.prefix(1).isEmpty ? "N" : nickname.prefix(1)))
                        .font(.system(size: 38, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Label("닉네임", systemImage: "person")
                        .font(.normiCaption.weight(.semibold))
                        .foregroundColor(.normiSubText)
                    TextField("닉네임을 입력하세요", text: $nickname)
                        .padding(14)
                        .background(Color.normiGray)
                        .cornerRadius(12)
                }
                .normiCard()
                .padding(.horizontal, 20)

                Button(action: saveProfile) {
                    HStack {
                        if isSaving { ProgressView().tint(.white) }
                        Text(isSaving ? "저장 중..." : "저장하기")
                    }
                }
                .buttonStyle(NormiPrimaryButton())
                .padding(.horizontal, 20)
                .disabled(nickname.isEmpty || isSaving)

                Spacer()
            }
            .padding(.top, 30)
            .navigationTitle("프로필 수정")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("닫기") { dismiss() }
                }
            }
            .onAppear { nickname = user.nickname }
        }
    }

    private func saveProfile() {
        isSaving = true
        let db = Firestore.firestore()
        db.collection("users").document(user.id)
            .updateData(["nickname": nickname]) { _ in
                Task { @MainActor in
                    await authVM.fetchUserProfile(uid: user.id)
                    isSaving = false
                    dismiss()
                }
            }
    }
}

import FirebaseFirestore
