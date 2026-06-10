// ============================================================
//  PostViewModel.swift
//  Firestore 기반 커뮤니티 글 읽기/쓰기/좋아요/댓글
//  Firebase Storage 기반 이미지 업로드
// ============================================================

import FirebaseCore
import Foundation
import Combine
import FirebaseFirestore
import FirebaseStorage
import FirebaseAuth
import UIKit

@MainActor
final class PostViewModel: ObservableObject {
    @Published var posts: [CommunityPost] = []
    @Published var comments: [Comment] = []
    @Published var isLoading   = false
    @Published var isUploading = false
    @Published var error: String?

    private let db      = Firestore.firestore()
    private let storage = Storage.storage()
    private var listener: ListenerRegistration?

    // MARK: - Real-time Listener

    func startListening() {
        isLoading = true
        listener = db.collection("posts")
            .order(by: "createdAt", descending: true)
            .limit(to: 50)
            .addSnapshotListener { [weak self] snap, err in
                Task { @MainActor in
                    if let err {
                        self?.error = err.localizedDescription
                        self?.isLoading = false
                        return
                    }
                    self?.posts = (snap?.documents ?? []).compactMap {
                        try? $0.data(as: CommunityPost.self)
                    }
                    self?.isLoading = false
                }
            }
    }

    func stopListening() { listener?.remove() }

    // MARK: - Create Post

    func createPost(
        content: String,
        images: [UIImage],
        station: String?,
        category: String?,
        author: NormiUser
    ) async {
        isUploading = true
        error = nil
        do {
            let imageURLs = try await uploadImages(images, uid: author.id ?? "")

            let post = CommunityPost(
                authorUID:        author.id ?? "",
                authorNickname:   author.nickname,
                authorProfileURL: author.profileImageURL,
                content:          content,
                imageURLs:        imageURLs,
                station:          station,
                category:         category,
                likes:            0,
                likedBy:          [],
                commentCount:     0,
                createdAt:        Timestamp()
            )
            try db.collection("posts").addDocument(from: post)
        } catch {
            self.error = "글 등록에 실패했습니다: \(error.localizedDescription)"
        }
        isUploading = false
    }

    // MARK: - Like / Unlike

    func toggleLike(post: CommunityPost, uid: String?) {
        guard let uid = uid, let docID = post.id else { return }
        let ref = db.collection("posts").document(docID)

        if post.likedBy.contains(uid) {
            // 이미 좋아요한 경우 → 취소
            guard post.likes > 0 else { return }  // ✅ 음수 방지
            ref.updateData([
                "likes":   FieldValue.increment(Int64(-1)),
                "likedBy": FieldValue.arrayRemove([uid])
            ])
        } else {
            // 좋아요 안 누른 경우 → 추가
            ref.updateData([
                "likes":   FieldValue.increment(Int64(1)),
                "likedBy": FieldValue.arrayUnion([uid])
            ])
        }
    }

    // MARK: - Fetch Comments

    func fetchComments(postID: String) async -> [Comment] {
        do {
            let snap = try await db.collection("posts").document(postID)
                .collection("comments")
                .order(by: "createdAt")
                .getDocuments()
            return snap.documents.compactMap { try? $0.data(as: Comment.self) }
        } catch {
            return []
        }
    }

    // MARK: - Add Comment

    func addComment(postID: String, content: String, author: NormiUser) async {
        let comment = Comment(
            authorUID:      author.id ?? "",
            authorNickname: author.nickname,
            content:        content,
            createdAt:      Timestamp()
        )
        do {
            try db.collection("posts").document(postID)
                .collection("comments").addDocument(from: comment)
            try await db.collection("posts").document(postID)
                .updateData(["commentCount": FieldValue.increment(Int64(1))])
        } catch {
            self.error = "댓글 등록에 실패했습니다."
        }
    }

    // MARK: - Delete Post

    func deletePost(_ post: CommunityPost, uid: String?) {
        guard let id = post.id,
              let uid = uid,
              post.authorUID == uid else { return }
        db.collection("posts").document(id).delete()
    }

    // MARK: - Image Upload (Firebase Storage)

    private func uploadImages(_ images: [UIImage], uid: String) async throws -> [String] {
        try await withThrowingTaskGroup(of: String.self) { group in
            for (i, img) in images.enumerated() {
                group.addTask {
                    guard let data = img.jpegData(compressionQuality: 0.7) else {
                        throw NSError(domain: "ImageError", code: -1)
                    }
                    let ref = Storage.storage().reference()
                        .child("posts/\(uid)/\(UUID().uuidString)_\(i).jpg")
                    _ = try await ref.putDataAsync(data)
                    return try await ref.downloadURL().absoluteString
                }
            }
            var urls: [String] = []
            for try await url in group { urls.append(url) }
            return urls
        }
    }
}
