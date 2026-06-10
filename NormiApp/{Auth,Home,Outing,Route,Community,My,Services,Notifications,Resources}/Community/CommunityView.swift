// ============================================================
//  CommunityView.swift
//  화면 8 — 커뮤니티: 소풍 기록 / 함께해요 탭
//  사진과 글 게시, 모든 사용자에게 공개
// ============================================================

import SwiftUI

struct CommunityView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @StateObject private var vm = PostViewModel()
    @State private var selectedTab = 0          // 0=소풍기록 1=함께해요
    @State private var showCreate  = false

    var body: some View {
        NavigationView {
            ZStack(alignment: .bottomTrailing) {
                Color.normiGray.ignoresSafeArea()

                VStack(spacing: 0) {
                    // 탭 세그먼트 (와이어프레임 화면8 상단)
                    segmentControl

                    // 피드
                    if vm.isLoading {
                        Spacer()
                        ProgressView("불러오는 중...")
                        Spacer()
                    } else if vm.posts.isEmpty {
                        emptyState
                    } else {
                        postFeed
                    }
                }

                // 글쓰기 FAB
                Button(action: { showCreate = true }) {
                    Image(systemName: "plus")
                        .font(.title2.weight(.semibold))
                        .foregroundColor(.white)
                        .frame(width: 56, height: 56)
                        .background(Color.normiBlue)
                        .clipShape(Circle())
                        .shadow(color: Color.normiBlue.opacity(0.4), radius: 8, y: 4)
                }
                .padding(.trailing, 20)
                .padding(.bottom, 20)
            }
            .navigationTitle("커뮤니티")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showCreate) {
                if let user = authVM.currentUser {
                    CreatePostView(vm: vm, user: user)
                }
            }
        }
        .onAppear  { vm.startListening() }
        .onDisappear { vm.stopListening() }
    }

    // MARK: - 탭 세그먼트

    private var segmentControl: some View {
        HStack(spacing: 0) {
            ForEach([("소풍 기록", 0), ("함께해요", 1)], id: \.1) { label, idx in
                Button(action: { selectedTab = idx }) {
                    VStack(spacing: 0) {
                        Text(label)
                            .font(.normiHeadline)
                            .foregroundColor(selectedTab == idx ? .normiBlue : .normiSubText)
                            .padding(.vertical, 14)
                            .frame(maxWidth: .infinity)
                        Rectangle()
                            .fill(selectedTab == idx ? Color.normiBlue : Color.clear)
                            .frame(height: 2)
                    }
                }
            }
        }
        .background(Color.white)
        .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
    }

    // MARK: - Post Feed

    private var postFeed: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 0) {
                ForEach(vm.posts) { post in
                    NavigationLink(destination: PostDetailView(post: post, vm: vm)) {
                        PostCardView(post: post, vm: vm)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                    }
                    .buttonStyle(PlainButtonStyle())
                    Divider().padding(.horizontal, 16)
                }
            }
            .padding(.bottom, 80)
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 60))
                .foregroundColor(.normiBlue.opacity(0.3))
            Text("아직 소풍 기록이 없어요\n첫 번째 소풍을 기록해 보세요!")
                .multilineTextAlignment(.center)
                .font(.normiBody)
                .foregroundColor(.normiSubText)
                .lineSpacing(4)
            Button(action: { showCreate = true }) {
                Label("소풍 기록 작성하기", systemImage: "pencil")
            }
            .buttonStyle(NormiPrimaryButton())
            .frame(maxWidth: 220)
            Spacer()
        }
    }
}

// MARK: - Post Card (와이어프레임 화면8 글 카드)

struct PostCardView: View {
    let post: CommunityPost
    @ObservedObject var vm: PostViewModel
    @EnvironmentObject var authVM: AuthViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 작성자 정보
            authorRow
            // 글 내용
            Text(post.content)
                .font(.normiBody)
                .foregroundColor(.normiText)
                .lineLimit(3)
                .lineSpacing(4)
                .frame(maxWidth: .infinity, alignment: .leading)
            // 사진 (있을 경우)
            if !post.imageURLs.isEmpty {
                imageGrid
            }
            // 방문 역 배지
            if let station = post.station {
                HStack(spacing: 4) {
                    Image(systemName: "tram").font(.caption)
                    Text(station).font(.normiCaption)
                }
                .foregroundColor(.normiBlue)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Color.normiSky)
                .cornerRadius(20)
            }
            // 좋아요 / 댓글
            actionRow
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.normiNavy.opacity(0.05), radius: 6, y: 2)
    }

    private var authorRow: some View {
        HStack(spacing: 10) {
            // 프로필 원형
            ZStack {
                Circle().fill(Color.normiBlue.opacity(0.15)).frame(width: 40, height: 40)
                Text(String(post.authorNickname.prefix(1)))
                    .font(.normiHeadline)
                    .foregroundColor(.normiBlue)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(post.authorNickname)
                    .font(.normiCaption.weight(.semibold))
                    .foregroundColor(.normiText)
                HStack(spacing: 4) {
                    Text(post.timeAgoText)
                    if let st = post.station {
                        Text("·")
                        Text(st)
                    }
                }
                .font(.normiCaption2)
                .foregroundColor(.normiSubText)
            }
            Spacer()
        }
    }

    // 이미지 그리드 (최대 3장 미리보기)
    private var imageGrid: some View {
        let urls = Array(post.imageURLs.prefix(3))
        return HStack(spacing: 4) {
            ForEach(urls, id: \.self) { url in
                AsyncImage(url: URL(string: url)) { img in
                    img.resizable().scaledToFill()
                } placeholder: {
                    Color.normiGray
                }
                .frame(maxWidth: .infinity)
                .frame(height: urls.count == 1 ? 180 : 100)
                .clipped()
                .cornerRadius(8)
            }
        }
    }

    private var actionRow: some View {
        HStack(spacing: 20) {
            // 좋아요
            Button(action: {
                guard let uid = authVM.currentUser?.id else { return }
                vm.toggleLike(post: post, uid: uid)
            }) {
                HStack(spacing: 4) {
                    Image(systemName: post.likedBy.contains(authVM.currentUser?.id ?? "") ? "heart.fill" : "heart")
                        .foregroundColor(post.likedBy.contains(authVM.currentUser?.id ?? "") ? .normiRed : .normiSubText)
                    Text("\(post.likes)")
                        .font(.normiCaption)
                        .foregroundColor(.normiSubText)
                }
            }
            // 댓글
            HStack(spacing: 4) {
                Image(systemName: "bubble.left").foregroundColor(.normiSubText)
                Text("\(post.commentCount)").font(.normiCaption).foregroundColor(.normiSubText)
            }
            Spacer()
        }
    }
}
