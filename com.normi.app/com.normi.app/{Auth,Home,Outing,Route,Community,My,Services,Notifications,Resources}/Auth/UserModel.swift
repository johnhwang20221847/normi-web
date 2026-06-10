// ============================================================
//  UserModel.swift
// ============================================================

import Foundation
import FirebaseFirestore  // ← 추가

struct NormiUser: Identifiable, Codable {
    @DocumentID var id: String?  // ← var id: String → @DocumentID var id: String?
    var nickname: String
    var email: String
    var profileImageURL: String?
    var createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id, nickname, email, profileImageURL, createdAt
    }
}
