import SwiftUI

// MARK: - 이용약관 동의 화면 (Apple Guideline 1.2 대응)
// 회원가입 전 반드시 표시해야 합니다

struct TermsAgreementView: View {
    @Binding var isPresented: Bool
    var onAgreed: () -> Void

    @State private var agreedToTerms = false
    @State private var agreedToPrivacy = false
    @State private var agreedToCommunity = false
    @State private var showTermsDetail: TermsType? = nil

    private var allAgreed: Bool {
        agreedToTerms && agreedToPrivacy && agreedToCommunity
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {

                    // 헤더
                    VStack(alignment: .leading, spacing: 8) {
                        Text("노르미 서비스 이용약관")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        Text("서비스를 이용하시려면 아래 약관에 동의해주세요.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 8)

                    Divider()

                    // 전체 동의
                    Button {
                        let newValue = !allAgreed
                        agreedToTerms = newValue
                        agreedToPrivacy = newValue
                        agreedToCommunity = newValue
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: allAgreed ? "checkmark.circle.fill" : "circle")
                                .font(.title3)
                                .foregroundColor(allAgreed ? .blue : .gray)
                            Text("전체 동의")
                                .font(.body)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                            Spacer()
                        }
                        .padding(16)
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }

                    // 개별 약관 항목
                    VStack(spacing: 12) {
                        TermsRowView(
                            isChecked: $agreedToTerms,
                            title: "서비스 이용약관 (필수)",
                            onDetailTap: { showTermsDetail = .service }
                        )
                        TermsRowView(
                            isChecked: $agreedToPrivacy,
                            title: "개인정보 처리방침 (필수)",
                            onDetailTap: { showTermsDetail = .privacy }
                        )
                        TermsRowView(
                            isChecked: $agreedToCommunity,
                            title: "커뮤니티 가이드라인 (필수)",
                            onDetailTap: { showTermsDetail = .community }
                        )
                    }

                    // 커뮤니티 핵심 규칙 요약 (Apple이 요구하는 명시적 고지)
                    VStack(alignment: .leading, spacing: 10) {
                        Text("커뮤니티 규칙 요약")
                            .font(.footnote)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)

                        CommunityRuleRow(icon: "hand.raised.slash", text: "욕설 및 혐오 발언 금지")
                        CommunityRuleRow(icon: "exclamationmark.shield", text: "성적·폭력적 콘텐츠 금지")
                        CommunityRuleRow(icon: "person.2.slash", text: "타인 괴롭힘(사이버불링) 금지")
                        CommunityRuleRow(icon: "envelope.badge.shield.half.filled", text: "스팸·광고성 게시글 금지")
                        CommunityRuleRow(icon: "trash", text: "위반 시 게시글 삭제 및 계정 정지")
                    }
                    .padding(16)
                    .background(Color(.systemYellow).opacity(0.1))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.yellow.opacity(0.4), lineWidth: 1)
                    )

                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 120)
            }
            .navigationBarTitleDisplayMode(.inline)
            .overlay(alignment: .bottom) {
                // 동의 버튼
                VStack(spacing: 0) {
                    Divider()
                    Button {
                        onAgreed()
                        isPresented = false
                    } label: {
                        Text("동의하고 시작하기")
                            .font(.body)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(allAgreed ? Color.blue : Color.gray)
                            .cornerRadius(14)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 16)
                    }
                    .disabled(!allAgreed)
                }
                .background(Color(.systemBackground))
            }
        }
        .sheet(item: $showTermsDetail) { type in
            TermsDetailView(termsType: type)
        }
    }
}

// MARK: - 약관 행 컴포넌트
struct TermsRowView: View {
    @Binding var isChecked: Bool
    let title: String
    let onDetailTap: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button { isChecked.toggle() } label: {
                Image(systemName: isChecked ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundColor(isChecked ? .blue : .gray)
            }
            Text(title)
                .font(.subheadline)
                .foregroundColor(.primary)
            Spacer()
            Button("보기") { onDetailTap() }
                .font(.subheadline)
                .foregroundColor(.blue)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - 커뮤니티 규칙 행
struct CommunityRuleRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundColor(.orange)
                .frame(width: 20)
            Text(text)
                .font(.subheadline)
                .foregroundColor(.primary)
        }
    }
}

// MARK: - 약관 상세 보기
enum TermsType: Identifiable {
    case service, privacy, community
    var id: Self { self }
    var title: String {
        switch self {
        case .service: return "서비스 이용약관"
        case .privacy: return "개인정보 처리방침"
        case .community: return "커뮤니티 가이드라인"
        }
    }
}

struct TermsDetailView: View {
    let termsType: TermsType
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                Text(termsContent)
                    .font(.body)
                    .foregroundColor(.primary)
                    .lineSpacing(6)
                    .padding(20)
            }
            .navigationTitle(termsType.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("닫기") { dismiss() }
                }
            }
        }
    }

    private var termsContent: String {
        switch termsType {
        case .service:
            return """
            제1조 (목적)
            본 약관은 노르미(이하 "서비스")가 제공하는 모든 서비스의 이용 조건 및 절차, 기타 필요한 사항을 규정합니다.

            제2조 (금지 행위)
            다음 행위는 엄격히 금지됩니다:
            • 욕설, 비방, 혐오 발언
            • 성적·폭력적 콘텐츠 게시
            • 타인 개인정보 무단 수집 및 배포
            • 스팸·광고성 게시물 반복 게시
            • 타인 사칭

            제3조 (제재)
            위반 시 사전 경고 없이 게시글 삭제, 이용 제한, 계정 영구 정지 조치가 취해질 수 있습니다.

            제4조 (면책)
            서비스는 사용자가 게시한 콘텐츠에 대한 법적 책임을 지지 않습니다.
            """
        case .privacy:
            return """
            제1조 (수집하는 개인정보)
            • 이메일 주소
            • 닉네임
            • 프로필 사진 (선택)
            • 서비스 이용 기록

            제2조 (이용 목적)
            수집된 정보는 서비스 제공, 부정 이용 방지, 고객 지원에만 사용됩니다.

            제3조 (보유 기간)
            회원 탈퇴 시 즉시 파기합니다. 단, 관련 법령에 따라 일부 정보는 일정 기간 보관될 수 있습니다.

            제4조 (제3자 제공)
            법령에 의한 경우를 제외하고 제3자에게 개인정보를 제공하지 않습니다.
            """
        case .community:
            return """
            노르미 커뮤니티 가이드라인

            노르미는 모든 사용자가 안전하고 즐겁게 이용할 수 있는 공간을 지향합니다.

            [허용하지 않는 콘텐츠]
            • 욕설, 비방, 혐오 표현
            • 성적·폭력적·자해 관련 콘텐츠
            • 개인정보 무단 공개 (doxxing)
            • 스팸, 낚시성 게시글
            • 허위 정보 유포
            • 타인 괴롭힘 (사이버불링)

            [신고 방법]
            게시글 또는 댓글 우측 상단 메뉴(⋯)를 통해 신고하실 수 있습니다. 신고된 콘텐츠는 24시간 이내 검토됩니다.

            [차단 기능]
            불쾌한 사용자는 프로필에서 차단할 수 있습니다. 차단된 사용자의 콘텐츠는 보이지 않습니다.

            [제재 정책]
            경미한 위반: 콘텐츠 삭제
            반복 위반: 일시적 이용 제한
            심각한 위반: 계정 영구 정지

            노르미 운영팀은 건강한 커뮤니티를 위해 최선을 다하겠습니다.
            """
        }
    }
}

#Preview {
    TermsAgreementView(isPresented: .constant(true)) {}
}
