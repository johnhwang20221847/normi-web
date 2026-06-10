import SwiftUI

// MARK: - 신고 시트 뷰 (Apple Guideline 1.2 - 신고 기능)
// 게시글, 댓글, 사용자 신고에 모두 사용 가능

struct ReportSheetView: View {
    let targetType: ReportTargetType
    let targetID: String
    let targetName: String          // 게시글 제목 또는 닉네임

    @StateObject private var viewModel = ReportBlockViewModel()
    @Environment(\.dismiss) var dismiss

    @State private var selectedReason: ReportReason? = nil
    @State private var detailText = ""
    @State private var showSuccess = false

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 0) {

                // 신고 대상 정보
                HStack(spacing: 12) {
                    Image(systemName: targetTypeIcon)
                        .font(.title3)
                        .foregroundColor(.red)
                        .frame(width: 36, height: 36)
                        .background(Color.red.opacity(0.1))
                        .clipShape(Circle())

                    VStack(alignment: .leading, spacing: 2) {
                        Text(targetTypeLabel + " 신고")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text(targetName)
                            .font(.body)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                            .lineLimit(1)
                    }
                    Spacer()
                }
                .padding(16)
                .background(Color(.systemGray6))

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {

                        // 신고 사유 선택
                        VStack(alignment: .leading, spacing: 12) {
                            Text("신고 사유를 선택해주세요")
                                .font(.body)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)

                            ForEach(ReportReason.allCases) { reason in
                                Button {
                                    selectedReason = reason
                                } label: {
                                    HStack(spacing: 12) {
                                        Image(systemName: selectedReason == reason
                                              ? "checkmark.circle.fill"
                                              : "circle")
                                            .foregroundColor(selectedReason == reason ? .red : .gray)
                                            .font(.body)

                                        Text(reason.rawValue)
                                            .font(.subheadline)
                                            .foregroundColor(.primary)

                                        Spacer()
                                    }
                                    .padding(.vertical, 4)
                                }
                            }
                        }
                        .padding(16)
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)

                        // 추가 설명 (선택)
                        VStack(alignment: .leading, spacing: 8) {
                            Text("추가 설명 (선택)")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)

                            TextField(
                                "신고 내용을 자세히 적어주시면 빠른 검토에 도움이 됩니다.",
                                text: $detailText,
                                axis: .vertical
                            )
                            .font(.subheadline)
                            .lineLimit(4...6)
                            .padding(12)
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                        }

                        // 안내 문구
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "info.circle")
                                .font(.subheadline)
                                .foregroundColor(.blue)
                            Text("신고된 콘텐츠는 24시간 이내 검토됩니다. 허위 신고는 서비스 이용이 제한될 수 있습니다.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineSpacing(4)
                        }
                        .padding(12)
                        .background(Color.blue.opacity(0.05))
                        .cornerRadius(10)
                    }
                    .padding(16)
                    .padding(.bottom, 100)
                }
                .overlay(alignment: .bottom) {
                    // 제출 버튼
                    VStack(spacing: 0) {
                        Divider()
                        Button {
                            Task { await submitReport() }
                        } label: {
                            Group {
                                if viewModel.isLoading {
                                    ProgressView()
                                        .progressViewStyle(.circular)
                                        .tint(.white)
                                } else {
                                    Text("신고 제출")
                                        .font(.body)
                                        .fontWeight(.semibold)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .foregroundColor(.white)
                            .background(selectedReason != nil ? Color.red : Color.gray)
                            .cornerRadius(14)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                        }
                        .disabled(selectedReason == nil || viewModel.isLoading)
                    }
                    .background(Color(.systemBackground))
                }
            }
            .navigationTitle("신고하기")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("취소") { dismiss() }
                }
            }
            .alert("신고 접수 완료", isPresented: $showSuccess) {
                Button("확인") { dismiss() }
            } message: {
                Text(viewModel.successMessage ?? "신고가 접수되었습니다.")
            }
            .alert("오류", isPresented: .init(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            )) {
                Button("확인") { viewModel.errorMessage = nil }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
    }

    private func submitReport() async {
        guard let reason = selectedReason else { return }
        await viewModel.submitReport(
            targetType: targetType,
            targetID: targetID,
            reason: reason,
            detail: detailText
        )
        if viewModel.successMessage != nil {
            showSuccess = true
        }
    }

    private var targetTypeIcon: String {
        switch targetType {
        case .post:    return "doc.text"
        case .comment: return "bubble.left"
        case .user:    return "person"
        }
    }

    private var targetTypeLabel: String {
        switch targetType {
        case .post:    return "게시글"
        case .comment: return "댓글"
        case .user:    return "사용자"
        }
    }
}

// MARK: - 신고 버튼 (게시글/댓글 메뉴에서 사용)
// 사용 예시: PostDetailView, CommunityView의 ContextMenu에 추가
struct ReportMenuButton: View {
    let targetType: ReportTargetType
    let targetID: String
    let targetName: String

    @State private var showReportSheet = false

    var body: some View {
        Button(role: .destructive) {
            showReportSheet = true
        } label: {
            Label("신고하기", systemImage: "exclamationmark.triangle")
        }
        .sheet(isPresented: $showReportSheet) {
            ReportSheetView(
                targetType: targetType,
                targetID: targetID,
                targetName: targetName
            )
        }
    }
}

#Preview {
    ReportSheetView(
        targetType: .post,
        targetID: "samplePostID",
        targetName: "오늘 날씨 어때요?"
    )
}
