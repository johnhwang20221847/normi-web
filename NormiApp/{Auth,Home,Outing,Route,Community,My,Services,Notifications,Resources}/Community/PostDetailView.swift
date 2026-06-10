// ============================================================
//  PostDetailView.swift
//  게시글 상세 + 댓글 기능
// ============================================================

import SwiftUI

struct PostDetailView: View {
    let post: CommunityPost
    @ObservedObject var vm: PostViewModel
    @EnvironmentObject var authVM: AuthViewModel

    @State private var comments: [Comment] = []
    @State private var commentText = ""
    @State private var isLoadingComments = false
    @FocusState private var commentFocused: Bool

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.normiGray.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // 상단 글 본문
                    postContent
                    // 이미지 갤러리
                    if !post.imageURLs.isEmpty { imageGallery }
                    // 구분선
                    Divider().padding(.vertical, 16)
                    // 댓글 목록
                    commentsSection
                    Spacer(minLength: 80)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
            }

            // 댓글 입력 바
            commentInputBar
        }
        .navigationTitle("소풍 기록")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if post.authorUID == authVM.currentUser?.id {
                    Button("삭제") {
                        vm.deletePost(post, uid: authVM.currentUser?.id ?? "")
                    }
                    .foregroundColor(.normiRed)
                }
            }
        }
        .task { await loadComments() }
    }

    // MARK: - 본문

    private var postContent: some View {
        VStack(alignment: .leading, spacing: 14) {
            // 작성자
            HStack(spacing: 12) {
                ZStack {
                    Circle().fill(Color.normiBlue.opacity(0.15)).frame(width: 48, height: 48)
                    Text(String(post.authorNickname.prefix(1)))
                        .font(.normiTitle2)
                        .foregroundColor(.normiBlue)
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text(post.authorNickname)
                        .font(.normiHeadline)
                        .foregroundColor(.normiText)
                    HStack(spacing: 4) {
                        Text(post.timeAgoText).font(.normiCaption).foregroundColor(.normiSubText)
                        if let st = post.station {
                            Text("·").foregroundColor(.normiSubText)
                            Label(st, systemImage: "tram")
                                .font(.normiCaption)
                                .foregroundColor(.normiBlue)
                        }
                    }
                }
                Spacer()
            }
            // 본문
            Text(post.content)
                .font(.normiBody)
                .foregroundColor(.normiText)
                .lineSpacing(6)
                .frame(maxWidth: .infinity, alignment: .leading)
            // 좋아요
            HStack(spacing: 6) {
                Button(action: {
                    guard let uid = authVM.currentUser?.id else { return }
                    vm.toggleLike(post: post, uid: uid)
                }) {
                    Image(systemName: post.likedBy.contains(authVM.currentUser?.id ?? "") ? "heart.fill" : "heart")
                        .foregroundColor(post.likedBy.contains(authVM.currentUser?.id ?? "") ? .normiRed : .normiSubText)
                    Text("\(post.likes) 명이 좋아해요")
                        .font(.normiCaption)
                        .foregroundColor(.normiSubText)
                }
            }
        }
    }

    // MARK: - 이미지

    private var imageGallery: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(post.imageURLs, id: \.self) { url in
                    AsyncImage(url: URL(string: url)) { img in
                        img.resizable().scaledToFill()
                    } placeholder: {
                        Color.normiGray.overlay(ProgressView())
                    }
                    .frame(width: 240, height: 180)
                    .clipped()
                    .cornerRadius(14)
                }
            }
        }
        .padding(.top, 12)
    }

    // MARK: - 댓글

    private var commentsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("댓글 \(comments.count)개")
                .font(.normiHeadline)
                .foregroundColor(.normiNavy)

            if isLoadingComments {
                ProgressView().padding()
            } else if comments.isEmpty {
                Text("첫 댓글을 남겨보세요 😊")
                    .font(.normiCaption)
                    .foregroundColor(.normiSubText)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                ForEach(comments) { comment in
                    commentRow(comment)
                }
            }
        }
    }

    private func commentRow(_ comment: Comment) -> some View {
        HStack(alignment: .top, spacing: 10) {
            ZStack {
                Circle().fill(Color.normiGray).frame(width: 36, height: 36)
                Text(String(comment.authorNickname.prefix(1)))
                    .font(.normiCaption.weight(.semibold))
                    .foregroundColor(.normiNavy)
            }
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(comment.authorNickname)
                        .font(.normiCaption.weight(.semibold))
                        .foregroundColor(.normiText)
                    Spacer()
                    let secs = Date().timeIntervalSince(comment.createdAt.dateValue())
                    Text(secs < 60 ? "방금 전" : "\(Int(secs/60))분 전")
                        .font(.normiCaption2)
                        .foregroundColor(.normiSubText)
                }
                Text(comment.content)
                    .font(.normiBody)
                    .foregroundColor(.normiText)
                    .lineSpacing(3)
            }
        }
        .padding(12)
        .background(Color.white)
        .cornerRadius(12)
    }

    // MARK: - 댓글 입력 바

    private var commentInputBar: some View {
        HStack(spacing: 10) {
            TextField("댓글을 입력하세요...", text: $commentText)
                .focused($commentFocused)
                .padding(12)
                .background(Color.normiGray)
                .cornerRadius(22)

            Button(action: {
                guard !commentText.isEmpty, let user = authVM.currentUser, let id = post.id else { return }
                Task {
                    await vm.addComment(postID: id, content: commentText, author: user)
                    commentText = ""
                    await loadComments()
                }
            }) {
                Image(systemName: "paperplane.fill")
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(commentText.isEmpty ? Color.normiSubText : Color.normiBlue)
                    .clipShape(Circle())
            }
            .disabled(commentText.isEmpty)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            Color.white
                .shadow(color: .black.opacity(0.06), radius: 8, y: -2)
        )
    }

    private func loadComments() async {
        guard let id = post.id else { return }
        isLoadingComments = true
        comments = await vm.fetchComments(postID: id)
        isLoadingComments = false
    }
}
