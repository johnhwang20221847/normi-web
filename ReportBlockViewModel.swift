import Foundation
import FirebaseFirestore
import FirebaseAuth

// MARK: - 신고 모델
struct Report: Codable, Identifiable {
    @DocumentID var id: String?
    let reporterUID: String
    let targetType: ReportTargetType   // post / comment / user
    let targetID: String               // postID / commentID / userUID
    let reason: ReportReason
    let detail: String
    let createdAt: Timestamp

    init(
        reporterUID: String,
        targetType: ReportTargetType,
        targetID: String,
        reason: ReportReason,
        detail: String = ""
    ) {
        self.reporterUID = reporterUID
        self.targetType = targetType
        self.targetID = targetID
        self.reason = reason
        self.detail = detail
        self.createdAt = Timestamp()
    }
}

enum ReportTargetType: String, Codable {
    case post = "post"
    case comment = "comment"
    case user = "user"
}

enum ReportReason: String, Codable, CaseIterable, Identifiable {
    case hate        = "혐오·차별 발언"
    case sexual      = "성적·불쾌한 콘텐츠"
    case violence    = "폭력·위험 콘텐츠"
    case spam        = "스팸·광고"
    case harassment  = "괴롭힘·사이버불링"
    case falseInfo   = "허위 정보"
    case privacy     = "개인정보 침해"
    case other       = "기타"

    var id: Self { self }
}

// MARK: - 차단 모델
struct BlockedUser: Codable, Identifiable {
    @DocumentID var id: String?
    let blockerUID: String
    let blockedUID: String
    let blockedNickname: String
    let createdAt: Timestamp

    init(blockerUID: String, blockedUID: String, blockedNickname: String) {
        self.blockerUID = blockerUID
        self.blockedUID = blockedUID
        self.blockedNickname = blockedNickname
        self.createdAt = Timestamp()
    }
}

// MARK: - ReportBlockViewModel
@MainActor
final class ReportBlockViewModel: ObservableObject {

    @Published var blockedUIDs: Set<String> = []
    @Published var isLoading = false
    @Published var successMessage: String? = nil
    @Published var errorMessage: String? = nil

    private let db = Firestore.firestore()
    private var currentUID: String? { Auth.auth().currentUser?.uid }

    // MARK: - 신고 제출
    func submitReport(
        targetType: ReportTargetType,
        targetID: String,
        reason: ReportReason,
        detail: String = ""
    ) async {
        guard let uid = currentUID else { return }
        isLoading = true
        defer { isLoading = false }

        let report = Report(
            reporterUID: uid,
            targetType: targetType,
            targetID: targetID,
            reason: reason,
            detail: detail
        )

        do {
            try db.collection("reports").addDocument(from: report)
            successMessage = "신고가 접수되었습니다. 검토 후 조치하겠습니다."
        } catch {
            errorMessage = "신고 접수 중 오류가 발생했습니다."
        }
    }

    // MARK: - 사용자 차단
    func blockUser(blockedUID: String, blockedNickname: String) async {
        guard let uid = currentUID, uid != blockedUID else { return }
        isLoading = true
        defer { isLoading = false }

        let block = BlockedUser(
            blockerUID: uid,
            blockedUID: blockedUID,
            blockedNickname: blockedNickname
        )

        do {
            try db.collection("blocks").addDocument(from: block)
            blockedUIDs.insert(blockedUID)
            successMessage = "\(blockedNickname)님을 차단했습니다."
        } catch {
            errorMessage = "차단 처리 중 오류가 발생했습니다."
        }
    }

    // MARK: - 차단 해제
    func unblockUser(blockedUID: String) async {
        guard let uid = currentUID else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            let snapshot = try await db.collection("blocks")
                .whereField("blockerUID", isEqualTo: uid)
                .whereField("blockedUID", isEqualTo: blockedUID)
                .getDocuments()

            for doc in snapshot.documents {
                try await doc.reference.delete()
            }
            blockedUIDs.remove(blockedUID)
            successMessage = "차단이 해제되었습니다."
        } catch {
            errorMessage = "차단 해제 중 오류가 발생했습니다."
        }
    }

    // MARK: - 차단 목록 로드
    func loadBlockedUsers() async {
        guard let uid = currentUID else { return }

        do {
            let snapshot = try await db.collection("blocks")
                .whereField("blockerUID", isEqualTo: uid)
                .getDocuments()

            let uids = snapshot.documents.compactMap { doc -> String? in
                try? doc.data(as: BlockedUser.self)
            }.map { $0.blockedUID }

            blockedUIDs = Set(uids)
        } catch {
            print("차단 목록 로드 실패: \(error)")
        }
    }

    // MARK: - 차단 여부 확인
    func isBlocked(_ uid: String) -> Bool {
        blockedUIDs.contains(uid)
    }
}
