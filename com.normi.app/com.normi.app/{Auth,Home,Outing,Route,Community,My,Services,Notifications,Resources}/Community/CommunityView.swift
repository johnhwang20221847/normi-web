import SwiftUI

struct CommunityView: View {
    @EnvironmentObject var authVM: AuthViewModel   // ✅ PostDetailView에 전달용
    @StateObject private var viewModel = PostViewModel()
    @StateObject private var reportVM = ReportBlockViewModel()
    @State private var showCreatePost = false

    private var filteredPosts: [CommunityPost] {
        viewModel.posts.filter { !reportVM.isBlocked($0.authorUID) }
    }

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    ProgressView("게시글 불러오는 중...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if filteredPosts.isEmpty {
                    ContentUnavailableView(
                        "게시글이 없습니다",
                        systemImage: "doc.text",
                        description: Text("첫 번째 게시글을 작성해보세요!")
                    )
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(filteredPosts) { post in
                                NavigationLink(destination: PostDetailView(post: post).environmentObject(authVM)) {
                                    PostCardView(post: post)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                    }
                }
            }
            .navigationTitle("커뮤니티")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showCreatePost = true } label: {
                        Image(systemName: "square.and.pencil")
                    }
                }
            }
            .task {
                await reportVM.loadBlockedUsers()
                viewModel.startListening()   // ✅ 실시간 게시글 로드
            }
            .onDisappear { viewModel.stopListening() }
            .sheet(isPresented: $showCreatePost) {
                if let user = authVM.currentUser {
                    CreatePostView(vm: viewModel, user: user)
                }
            }
        }
    }
}

// MARK: - PostCardView
struct PostCardView: View {
    let post: CommunityPost

    @State private var showReportSheet = false
    @State private var showBlockSheet = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {

            // 작성자 + ⋯ 메뉴
            HStack(alignment: .center) {
                // 프로필 아바타
                Circle()
                    .fill(Color(.systemGray4))
                    .frame(width: 36, height: 36)
                    .overlay(
                        Text(String(post.authorNickname.prefix(1)))
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text(post.authorNickname)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    Text(post.timeAgoText)          // CommunityPost.timeAgoText 사용
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                // ✅ 신고/차단 메뉴
                Menu {
                    Button(role: .destructive) {
                        showReportSheet = true
                    } label: {
                        Label("게시글 신고", systemImage: "exclamationmark.triangle")
                    }
                    Button(role: .destructive) {
                        showBlockSheet = true
                    } label: {
                        Label("작성자 차단", systemImage: "person.crop.circle.badge.xmark")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .padding(8)
                        .contentShape(Rectangle())
                }
            }

            // 본문 (title 없음 → content 사용)
            Text(post.content)
                .font(.body)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
                .lineLimit(2)
                .lineSpacing(4)

            // 역 이름 태그 (station이 있을 때만)
            if let station = post.station, !station.isEmpty {
                Label(station, systemImage: "tram.fill")
                    .font(.caption)
                    .foregroundColor(.blue)
            }

            // 하단 좋아요 · 댓글 수
            HStack(spacing: 16) {
                Label("\(post.likes)", systemImage: "heart")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Label("\(post.commentCount)", systemImage: "bubble.left")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 2)
        // ✅ 신고 시트
        .sheet(isPresented: $showReportSheet) {
            ReportSheetView(
                targetType: .post,
                targetID: post.id ?? "",
                targetName: String(post.content.prefix(30))   // title 없으므로 content 앞 30자
            )
        }
        // ✅ 차단 시트
        .sheet(isPresented: $showBlockSheet) {
            BlockUserView(
                targetUID: post.authorUID,
                targetNickname: post.authorNickname
            )
            .presentationDetents([.medium])
        }
    }
}
