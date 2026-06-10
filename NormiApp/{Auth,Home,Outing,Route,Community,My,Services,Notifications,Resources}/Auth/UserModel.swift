// ============================================================
//  UserModel.swift
// ============================================================

import Foundation

struct NormiUser: Identifiable, Codable {
    var id: String               // Firebase UID
    var nickname: String
    var email: String
    var profileImageURL: String?
    var createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id, nickname, email, profileImageURL, createdAt
    }
}
