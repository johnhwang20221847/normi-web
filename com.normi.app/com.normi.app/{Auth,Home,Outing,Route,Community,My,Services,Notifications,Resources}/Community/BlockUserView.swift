import SwiftUI

// MARK: - 사용자 차단 뷰 (Apple Guideline 1.2 - 차단 기능)
// ProfileView에서 호출하세요

struct BlockUserView: View {
    let targetUID: String
    let targetNickname: String

    @StateObject private var viewModel = ReportBlockViewModel()
    @Environment(\.dismiss) var dismiss

    @State private var showBlockConfirm = false
    @State private var showUnblockConfirm = false
    @State private var isBlocked = false
    @State private var showSuccess = false

    var body: some View {
        VStack(spacing: 20) {

            // 핸들바
            RoundedRectangle(cornerRadius: 3)
                .fill(Color(.systemGray4))
                .frame(width: 40, height: 5)
                .padding(.top, 12)

            // 대상 사용자 정보
            VStack(spacing: 8) {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 56))
                    .foregroundColor(.gray)

                Text(targetNickname)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
            }
            .padding(.top, 8)

            Divider()

            // 신고 버튼
            ActionSheetButton(
                icon: "exclamationmark.triangle",
                iconColor: .orange,
                title: "신고하기",
                subtitle: "부적절한 콘텐츠나 행동을 신고합니다"
            ) {
                dismiss()
                // ReportSheetView는 ProfileView에서 별도 sheet로 열기
            }

            // 차단 버튼
            ActionSheetButton(
                icon: isBlocked ? "person.crop.circle.badge.checkmark" : "person.crop.circle.badge.xmark",
                iconColor: isBlocked ? .green : .red,
                title: isBlocked ? "차단 해제" : "차단하기",
                subtitle: isBlocked
                    ? "차단을 해제하면 이 사용자의 콘텐츠가 다시 보입니다"
                    : "차단하면 이 사용자의 게시글과 댓글이 숨겨집니다"
            ) {
                if isBlocked {
                    showUnblockConfirm = true
                } else {
                    showBlockConfirm = true
                }
            }

            Spacer()

            // 취소
            Button("취소") { dismiss() }
                .font(.body)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color(.systemGray6))
                .cornerRadius(14)
                .padding(.horizontal, 16)
                .padding(.bottom, 32)
        }
        .task {
            await viewModel.loadBlockedUsers()
            isBlocked = viewModel.isBlocked(targetUID)
        }
        // 차단 확인 알림
        .alert("차단하기", isPresented: $showBlockConfirm) {
            Button("차단", role: .destructive) {
                Task { await blockUser() }
            }
            Button("취소", role: .cancel) {}
        } message: {
            Text("\(targetNickname)님을 차단하시겠어요?\n차단 후에는 이 사용자의 게시글과 댓글이 보이지 않습니다.")
        }
        // 차단 해제 확인
        .alert("차단 해제", isPresented: $showUnblockConfirm) {
            Button("해제") {
                Task { await unblockUser() }
            }
            Button("취소", role: .cancel) {}
        } message: {
            Text("\(targetNickname)님의 차단을 해제하시겠어요?")
        }
        // 성공 알림
        .alert("완료", isPresented: $showSuccess) {
            Button("확인") { dismiss() }
        } message: {
            Text(viewModel.successMessage ?? "처리가 완료되었습니다.")
        }
    }

    private func blockUser() async {
        await viewModel.blockUser(
            blockedUID: targetUID,
            blockedNickname: targetNickname
        )
        isBlocked = true
        showSuccess = true
    }

    private func unblockUser() async {
        await viewModel.unblockUser(blockedUID: targetUID)
        isBlocked = false
        showSuccess = true
    }
}

// MARK: - 액션 버튼 컴포넌트
struct ActionSheetButton: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(iconColor)
                    .frame(width: 44, height: 44)
                    .background(iconColor.opacity(0.1))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineSpacing(2)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
    }
}

// MARK: - 차단 버튼 (프로필 툴바용)
// ProfileView 상단 툴바에 추가하세요
struct BlockMenuButton: View {
    let targetUID: String
    let targetNickname: String
    @State private var showSheet = false

    var body: some View {
        Button {
            showSheet = true
        } label: {
            Image(systemName: "ellipsis")
                .font(.body)
                .foregroundColor(.primary)
        }
        .sheet(isPresented: $showSheet) {
            BlockUserView(
                targetUID: targetUID,
                targetNickname: targetNickname
            )
            .presentationDetents([.medium])
            .presentationDragIndicator(.hidden)
        }
    }
}

#Preview {
    BlockUserView(
        targetUID: "sampleUID123",
        targetNickname: "달리기왕"
    )
}
