import SwiftUI

// MARK: - PostDetailView (신고/차단 기능 통합)
// 기존 PostDetailView에서 아래 패턴을 참고하여 수정하세요

struct PostDetailView: View {
    let post: CommunityPost          // 기존 PostModel 사용
    @StateObject private var viewModel = PostViewModel()
    @StateObject private var reportVM = ReportBlockViewModel()

    @State private var commentText = ""
    @State private var showReportPost = false
    @State private var showBlockAuthor = false
    @State private var showReportComment: Comment? = nil  // 신고할 댓글

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {

                // ─── 게시글 헤더 ───────────────────────────────
                HStack(alignment: .top) {
                    // 작성자 아바타
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

                        Text(post.createdAt.dateValue().formatted(.relative(presentation: .named)))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    // ✅ 게시글 신고/차단 메뉴
                    Menu {
                        // 게시글 신고
                        Button(role: .destructive) {
                            showReportPost = true
                        } label: {
                            Label("게시글 신고", systemImage: "exclamationmark.triangle")
                        }

                        // 작성자 차단
                        Button(role: .destructive) {
                            showBlockAuthor = true
                        } label: {
                            Label("작성자 차단", systemImage: "person.crop.circle.badge.xmark")
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .padding(8)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)

                // ─── 게시글 내용 ───────────────────────────────
                VStack(alignment: .leading, spacing: 12) {
                    Text(post.title)
                        .font(.title3)             // ✅ 최소 17pt (가독성 개선)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)

                    Text(post.content)
                        .font(.body)               // ✅ 17pt (가독성 개선)
                        .foregroundColor(.primary)
                        .lineSpacing(6)
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)

                Divider().padding(.vertical, 16)

                // ─── 댓글 목록 ───────────────────────────────
                VStack(alignment: .leading, spacing: 0) {
                    Text("댓글 \(viewModel.comments.count)개")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 12)

                    ForEach(viewModel.comments.filter {
                        // ✅ 차단된 사용자 댓글 필터링
                        !reportVM.isBlocked($0.authorUID)
                    }) { comment in
                        CommentRowView(
                            comment: comment,
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
            // 댓글 입력창
            CommentInputView(text: $commentText) {
                guard !commentText.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                Task {
                    // await viewModel.addComment(postID: post.id ?? "", content: commentText, author: currentUser)
                    commentText = ""
                }
            }
        }
        // ✅ 게시글 신고 시트
        .sheet(isPresented: $showReportPost) {
            ReportSheetView(
                targetType: .post,
                targetID: post.id ?? "",
                targetName: post.title
            )
        }
        // ✅ 작성자 차단 시트
        .sheet(isPresented: $showBlockAuthor) {
            BlockUserView(
                targetUID: post.authorUID,
                targetNickname: post.authorNickname
            )
            .presentationDetents([.medium])
        }
        // ✅ 댓글 신고 시트
        .sheet(item: $showReportComment) { comment in
            ReportSheetView(
                targetType: .comment,
                targetID: comment.id ?? "",
                targetName: "\(comment.authorNickname): \(comment.content)"
            )
        }
        .task {
            await reportVM.loadBlockedUsers()
            viewModel.comments = await viewModel.fetchComments(postID: post.id ?? "")
        }
    }
}

// MARK: - 댓글 행 (신고 버튼 포함)
struct CommentRowView: View {
    let comment: Comment
    let onReport: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // 아바타
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
                        .font(.subheadline)        // ✅ 15pt 이상
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)

                    Text(comment.createdAt.dateValue().formatted(.relative(presentation: .named)))
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Spacer()

                    // ✅ 댓글 신고 버튼
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

                Text(comment.content)
                    .font(.body)                   // ✅ 17pt
                    .foregroundColor(.primary)
                    .lineSpacing(4)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
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
