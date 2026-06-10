// ============================================================
//  PostModel.swift
//  Firestore: collection("posts")
// ============================================================

import Foundation
import FirebaseFirestore

struct CommunityPost: Identifiable, Codable {
    @DocumentID var id: String?
    var authorUID: String
    var authorNickname: String
    var authorProfileURL: String?

    var content: String                  // 글 내용
    var imageURLs: [String]              // Firebase Storage 이미지 URL 목록
    var station: String?                 // 방문 역 이름
    var category: String?                // 소풍 카테고리

    var likes: Int
    var likedBy: [String]               // UID 목록
    var commentCount: Int

    var createdAt: Timestamp

    // 와이어프레임 화면8 - 시간 표시
    var timeAgoText: String {
        let secs = Date().timeIntervalSince(createdAt.dateValue())
        if secs < 60      { return "방금 전" }
        if secs < 3600    { return "\(Int(secs/60))분 전" }
        if secs < 86400   { return "\(Int(secs/3600))시간 전" }
        return "\(Int(secs/86400))일 전"
    }
}

struct Comment: Identifiable, Codable {
    @DocumentID var id: String?
    var authorUID: String
    var authorNickname: String
    var content: String
    var createdAt: Timestamp
}
