import FirebaseCore
import FirebaseFirestore
import SwiftUI

struct PostDetailView: View {
    let post: CommunityPost

    @EnvironmentObject var authVM: AuthViewModel
    @StateObject private var postVM   = PostViewModel()
    @StateObject private var reportVM = ReportBlockViewModel()

    @State private var commentText       = ""
    @State private var showReportPost    = false
    @State private var showBlockAuthor   = false
    @State private var showReportComment: Comment? = nil
    @State private var isLiking          = false  // ✅ 중복 탭 방지

    private var isMyPost: Bool {
        post.authorUID == authVM.currentUser?.id ?? ""
    }

    private var visibleComments: [Comment] {
        postVM.comments.filter { !reportVM.isBlocked($0.authorUID) }
    }

    // ✅ 현재 사용자가 좋아요 눌렀는지 여부
    private var isLiked: Bool {
        guard let uid = authVM.currentUser?.id else { return false }
        return post.likedBy.contains(uid)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {

                // ── 게시글 헤더 ──────────────────────────
                HStack(alignment: .top) {
                    Circle()
                        .fill(Color(.systemGray4))
                        .frame(width: 44, height: 44)
                        .overlay(
                            Text(String(post.authorNickname.prefix(1)))
                                .font(.body)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                        )

                    VStack(alignment: .leading, spacing: 4) {
                        Text(post.authorNickname)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        Text(post.timeAgoText)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Menu {
                        if isMyPost {
                            Button(role: .destructive) {
                                postVM.deletePost(post, uid: authVM.currentUser?.id)
                            } label: {
                                Label("게시글 삭제", systemImage: "trash")
                            }
                        } else {
                            Button(role: .destructive) { showReportPost = true } label: {
                                Label("게시글 신고", systemImage: "exclamationmark.triangle")
                            }
                            Button(role: .destructive) { showBlockAuthor = true } label: {
                                Label("작성자 차단", systemImage: "person.crop.circle.badge.xmark")
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .foregroundColor(.secondary)
                            .padding(8)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)

                // ── 게시글 본문 ──────────────────────────
                VStack(alignment: .leading, spacing: 12) {
                    Text(post.content)
                        .font(.body)
                        .foregroundColor(.primary)
                        .lineSpacing(6)

                    if let station = post.station, !station.isEmpty {
                        Label(station, systemImage: "tram.fill")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                    }

                    if let category = post.category, !category.isEmpty {
                        Text("#\(category)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    if !post.imageURLs.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(post.imageURLs, id: \.self) { url in
                                    AsyncImage(url: URL(string: url)) { img in
                                        img.resizable().scaledToFill()
                                    } placeholder: {
                                        Color(.systemGray5)
                                    }
                                    .frame(width: 200, height: 200)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                }
                            }
                        }
                    }

                    // ✅ 좋아요 버튼 — 중복 탭 방지 + 음수 방지
                    HStack(spacing: 16) {
                        Button {
                            guard !isLiking else { return }
                            isLiking = true
                            postVM.toggleLike(post: post, uid: authVM.currentUser?.id)
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                isLiking = false
                            }
                        } label: {
                            Label(
                                "\(max(0, post.likes))",  // ✅ 음수 방지
                                systemImage: isLiked ? "heart.fill" : "heart"
                            )
                            .font(.subheadline)
                            .foregroundColor(isLiked ? .red : .secondary)
                        }
                        .disabled(isLiking)

                        Label("\(post.commentCount)", systemImage: "bubble.left")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)

                Divider().padding(.vertical, 16)

                // ── 댓글 목록 ────────────────────────────
                VStack(alignment: .leading, spacing: 0) {
                    Text("댓글 \(visibleComments.count)개")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 12)

                    ForEach(visibleComments) { comment in
                        CommentRowView(
                            comment: comment,
                            isMyComment: comment.authorUID == authVM.currentUser?.id ?? "",
                            onReport: { showReportComment = comment }
                        )
                        Divider().padding(.leading, 56)
                    }
                }

                Spacer(minLength: 80)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            CommentInputView(text: $commentText) {
                guard !commentText.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                guard let user = authVM.currentUser else { return }
                let text = commentText
                commentText = ""
                Task {
                    await postVM.addComment(
                        postID: post.id ?? "",
                        content: text,
                        author: user
                    )
                    postVM.comments = await postVM.fetchComments(postID: post.id ?? "")
                }
            }
        }
        .sheet(isPresented: $showReportPost) {
            ReportSheetView(
                targetType: .post,
                targetID: post.id ?? "",
                targetName: String(post.content.prefix(30))
            )
        }
        .sheet(isPresented: $showBlockAuthor) {
            BlockUserView(targetUID: post.authorUID, targetNickname: post.authorNickname)
                .presentationDetents([.medium])
        }
        .sheet(item: $showReportComment) { comment in
            ReportSheetView(
                targetType: .comment,
                targetID: comment.id ?? "",
                targetName: "\(comment.authorNickname): \(comment.content)"
            )
        }
        .task {
            await reportVM.loadBlockedUsers()
            postVM.comments = await postVM.fetchComments(postID: post.id ?? "")
        }
    }
}

// MARK: - 댓글 행
struct CommentRowView: View {
    let comment: Comment
    let isMyComment: Bool
    let onReport: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Circle()
                .fill(Color(.systemGray5))
                .frame(width: 36, height: 36)
                .overlay(
                    Text(String(comment.authorNickname.prefix(1)))
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                )

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(comment.authorNickname)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    Text(timeAgo(comment.createdAt.dateValue()))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()

                    if !isMyComment {
                        Menu {
                            Button(role: .destructive, action: onReport) {
                                Label("댓글 신고", systemImage: "exclamationmark.triangle")
                            }
                        } label: {
                            Image(systemName: "ellipsis")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(4)
                        }
                    }
                }
                Text(comment.content)
                    .font(.body)
                    .foregroundColor(.primary)
                    .lineSpacing(4)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private func timeAgo(_ date: Date) -> String {
        let secs = Date().timeIntervalSince(date)
        if secs < 60    { return "방금 전" }
        if secs < 3600  { return "\(Int(secs/60))분 전" }
        if secs < 86400 { return "\(Int(secs/3600))시간 전" }
        return "\(Int(secs/86400))일 전"
    }
}

// MARK: - 댓글 입력창
struct CommentInputView: View {
    @Binding var text: String
    let onSubmit: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            TextField("댓글을 입력하세요...", text: $text, axis: .vertical)
                .font(.body)
                .lineLimit(1...4)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Color(.systemGray6))
                .cornerRadius(22)

            Button(action: onSubmit) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 32))
                    .foregroundColor(text.isEmpty ? .gray : .blue)
            }
            .disabled(text.isEmpty)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color(.systemBackground))
        .overlay(alignment: .top) { Divider() }
    }
}
