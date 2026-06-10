// ============================================================
//  CreatePostView.swift
//  글 작성: 사진 선택 / 텍스트 / 방문 역 / 카테고리
//  와이어프레임 화면8 - 등록하기 버튼
// ============================================================

import SwiftUI
import PhotosUI

struct CreatePostView: View {
    @ObservedObject var vm: PostViewModel
    let user: NormiUser
    @Environment(\.dismiss) var dismiss

    @State private var content      = ""
    @State private var stationText  = ""
    @State private var selectedCat  = ""
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var selectedImages: [UIImage]        = []

    private let maxChars    = 500
    private let categories  = ["시장 구경", "산·공원", "온천·목욕", "그냥 타기", "기타"]

    var body: some View {
        NavigationView {
            ZStack {
                Color.normiGray.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // 사진 선택 (최대 3장)
                        photoSection
                        // 글 내용
                        contentSection
                        // 방문 역
                        stationSection
                        // 카테고리
                        categorySection
                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                }

                // 업로드 오버레이
                if vm.isUploading {
                    Color.black.opacity(0.4).ignoresSafeArea()
                    VStack(spacing: 14) {
                        ProgressView().tint(.white).scaleEffect(1.4)
                        Text("소풍 기록 등록 중...").foregroundColor(.white).font(.normiHeadline)
                    }
                    .padding(30)
                    .background(.ultraThinMaterial)
                    .cornerRadius(16)
                }
            }
            .navigationTitle("소풍 기록 작성")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("취소") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("등록하기") {
                        Task {
                            await vm.createPost(
                                content:  content,
                                images:   selectedImages,
                                station:  stationText.isEmpty ? nil : stationText,
                                category: selectedCat.isEmpty ? nil : selectedCat,
                                author:   user
                            )
                            if vm.error == nil { dismiss() }
                        }
                    }
                    .font(.normiHeadline)
                    .foregroundColor(content.isEmpty ? .normiSubText : .normiBlue)
                    .disabled(content.isEmpty || vm.isUploading)
                }
            }
        }
    }

    // MARK: - 사진 선택

    private var photoSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("사진 추가 (최대 3장)", systemImage: "photo.on.rectangle")
                .font(.normiCaption.weight(.semibold))
                .foregroundColor(.normiSubText)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    // 선택된 사진들
                    ForEach(Array(selectedImages.enumerated()), id: \.offset) { i, img in
                        ZStack(alignment: .topTrailing) {
                            Image(uiImage: img)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 100, height: 100)
                                .clipped()
                                .cornerRadius(12)

                            Button(action: { selectedImages.remove(at: i) }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.white)
                                    .shadow(radius: 2)
                            }
                            .offset(x: 4, y: -4)
                        }
                    }

                    // 추가 버튼 (최대 3장)
                    if selectedImages.count < 3 {
                        PhotosPicker(
                            selection: $selectedItems,
                            maxSelectionCount: 3 - selectedImages.count,
                            matching: .images
                        ) {
                            VStack(spacing: 6) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(.normiBlue)
                                Text("사진 추가")
                                    .font(.normiCaption2)
                                    .foregroundColor(.normiSubText)
                            }
                            .frame(width: 100, height: 100)
                            .background(Color.normiSky)
                            .cornerRadius(12)
                        }
                        .onChange(of: selectedItems) { items in
                            Task {
                                for item in items {
                                    if let data = try? await item.loadTransferable(type: Data.self),
                                       let img  = UIImage(data: data) {
                                        selectedImages.append(img)
                                    }
                                }
                                selectedItems = []
                            }
                        }
                    }
                }
            }
        }
        .normiCard()
    }

    // MARK: - 글 내용

    private var contentSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("오늘 소풍은 어떠셨나요?", systemImage: "pencil")
                .font(.normiCaption.weight(.semibold))
                .foregroundColor(.normiSubText)

            ZStack(alignment: .topLeading) {
                if content.isEmpty {
                    Text("사진과 함께 소풍 이야기를 나눠보세요 😊")
                        .font(.normiBody)
                        .foregroundColor(.normiSubText.opacity(0.6))
                        .padding(.top, 8)
                        .padding(.leading, 4)
                }
                TextEditor(text: $content)
                    .font(.normiBody)
                    .frame(minHeight: 120)
                    .onChange(of: content) { v in
                        if v.count > maxChars { content = String(v.prefix(maxChars)) }
                    }
            }

            HStack {
                Spacer()
                Text("\(content.count)/\(maxChars)")
                    .font(.normiCaption2)
                    .foregroundColor(content.count > maxChars - 50 ? .normiRed : .normiSubText)
            }
        }
        .normiCard()
    }

    // MARK: - 방문 역

    private var stationSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("방문한 역", systemImage: "tram.fill")
                .font(.normiCaption.weight(.semibold))
                .foregroundColor(.normiSubText)
            TextField("예) 도봉산역, 소요산역...", text: $stationText)
                .padding(12)
                .background(Color.normiGray)
                .cornerRadius(10)
        }
        .normiCard()
    }

    // MARK: - 카테고리

    private var categorySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("소풍 종류", systemImage: "tag")
                .font(.normiCaption.weight(.semibold))
                .foregroundColor(.normiSubText)

            LazyVGrid(
                columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())],
                spacing: 8
            ) {
                ForEach(categories, id: \.self) { cat in
                    Button(action: { selectedCat = selectedCat == cat ? "" : cat }) {
                        Text(cat)
                            .font(.normiCaption.weight(.semibold))
                            .foregroundColor(selectedCat == cat ? .white : .normiNavy)
                            .padding(.vertical, 8)
                            .frame(maxWidth: .infinity)
                            .background(selectedCat == cat ? Color.normiBlue : Color.normiGray)
                            .cornerRadius(8)
                    }
                }
            }
        }
        .normiCard()
    }
}
