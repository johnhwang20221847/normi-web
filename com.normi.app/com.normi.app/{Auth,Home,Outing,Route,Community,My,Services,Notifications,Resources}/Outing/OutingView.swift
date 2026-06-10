// ============================================================
//  OutingView.swift
//  화면 4 — 소풍탭: 4가지 카테고리 선택 + 역 선택
//  카테고리: 시장 구경 / 산·공원 / 온천·목욕 / 그냥 타기
// ============================================================

import SwiftUI

// MARK: - Category Model

struct OutingCategory: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let emoji: String
    let color: Color
    let bgColor: Color
    let stations: [String]
}

// MARK: - Outing View

struct OutingView: View {
    @State private var selectedCategory: OutingCategory?
    @State private var showStationPicker = false

    let categories: [OutingCategory] = [
        OutingCategory(
            title: "시장 구경",
            subtitle: "활기찬 재래시장의 매력",
            emoji: "🏮",
            color: .categoryMarket,
            bgColor: Color(hex: "#FFF4EC"),
            stations: ["광장시장(종로4가)", "남대문시장(회현)", "통인시장(경복궁)", "인천시장(인천시청)", "수원역(수원시장)", "전통시장(청량리)"]
        ),
        OutingCategory(
            title: "산·공원",
            subtitle: "자연 속 힐링 나들이",
            emoji: "⛰️",
            color: .categoryNature,
            bgColor: Color(hex: "#EDFBF4"),
            stations: ["도봉산역", "수락산역", "불암산역", "소요산역", "용마산역", "인릉산역", "청계산입구역"]
        ),
        OutingCategory(
            title: "온천·목욕",
            subtitle: "따뜻하게 피로를 풀어요",
            emoji: "♨️",
            color: .categorySpa,
            bgColor: Color(hex: "#F2F0FF"),
            stations: ["온양온천역", "유성온천역", "이천역(이천온천)", "수안보온천(충주)", "덕구온천(울진)"]
        ),
        OutingCategory(
            title: "그냥 타기",
            subtitle: "목적지 없이 자유롭게",
            emoji: "🚃",
            color: .categoryFree,
            bgColor: Color(hex: "#EBF3FF"),
            stations: ["소요산역(종착)", "인천역(종착)", "광운대역", "신창역(장항선 종착)", "천안역"]
        ),
    ]

    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()  // ✅ 다크모드 수정

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        headerSection
                        categoryGrid
                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                }
            }
            .navigationTitle("소풍 떠나기")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showStationPicker) {
                if let cat = selectedCategory {
                    StationPickerView(category: cat)
                }
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("어떤 소풍을 떠나볼까요?")
                .font(.normiTitle2)
                .foregroundColor(.normiNavy)
            Text("원하는 카테고리를 선택하면\n추천 역을 안내해 드려요.")
                .font(.normiBody)
                .foregroundColor(.normiSubText)
                .lineSpacing(4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - 4-Category Grid (2x2) ✅ 균일한 크기로 수정

    private var categoryGrid: some View {
        GeometryReader { geo in
            let spacing: CGFloat = 14
            let cardWidth = (geo.size.width - spacing) / 2

            LazyVGrid(
                columns: [
                    GridItem(.fixed(cardWidth), spacing: spacing),
                    GridItem(.fixed(cardWidth), spacing: spacing)
                ],
                spacing: spacing
            ) {
                ForEach(categories) { category in
                    categoryCard(category, width: cardWidth)
                        .onTapGesture {
                            selectedCategory = category
                            showStationPicker = true
                        }
                }
            }
        }
        .frame(height: 340)  // 카드 2행 높이 고정
    }

    private func categoryCard(_ cat: OutingCategory, width: CGFloat) -> some View {
        VStack(spacing: 0) {
            // 상단 이모지 영역
            ZStack {
                cat.bgColor
                VStack(spacing: 8) {
                    Text(cat.emoji)
                        .font(.system(size: 48))
                    Text(cat.title)
                        .font(.normiTitle2)
                        .foregroundColor(cat.color)
                        .fontWeight(.bold)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
            }
            .frame(width: width, height: 120)  // ✅ 고정 크기

            // 하단 설명 영역
            VStack(alignment: .leading, spacing: 6) {
                Text(cat.subtitle)
                    .font(.normiCaption)
                    .foregroundColor(.normiSubText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                HStack {
                    Text("역 선택하기")
                        .font(.normiCaption.weight(.semibold))
                        .foregroundColor(cat.color)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(cat.color)
                }
            }
            .padding(12)
            .frame(width: width)  // ✅ 고정 너비
            .background(Color(.systemBackground))  // ✅ 다크모드 수정
        }
        .frame(width: width)  // ✅ 전체 카드 너비 고정
        .cornerRadius(18)
        .shadow(color: cat.color.opacity(0.12), radius: 8, y: 3)
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(cat.color.opacity(0.15), lineWidth: 1)
        )
    }
}

// MARK: - Station Picker Sheet

struct StationPickerView: View {
    let category: OutingCategory
    @Environment(\.dismiss) var dismiss
    @StateObject private var routeVM = RouteViewModel()
    @State private var selectedStation: String?
    @State private var showRoute = false

    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()  // ✅ 다크모드 수정

                VStack(spacing: 0) {
                    categoryBadge

                    ScrollView {
                        VStack(spacing: 12) {
                            Text("추천 역을 선택하세요")
                                .font(.normiHeadline)
                                .foregroundColor(.normiNavy)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 20)
                                .padding(.top, 20)

                            ForEach(category.stations, id: \.self) { station in
                                stationRow(station)
                            }
                            Spacer(minLength: 40)
                        }
                    }

                    if selectedStation != nil {
                        VStack(spacing: 0) {
                            Divider()
                            NavigationLink(
                                destination: RouteSearchView(presetArrival: selectedStation ?? ""),
                                isActive: $showRoute
                            ) {
                                Button(action: { showRoute = true }) {
                                    HStack {
                                        Image(systemName: "tram.fill")
                                        Text("경로 찾기")
                                    }
                                }
                                .buttonStyle(NormiPrimaryButton())
                                .padding(.horizontal, 20)
                                .padding(.vertical, 16)
                            }
                        }
                        .background(Color(.systemBackground))  // ✅ 다크모드 수정
                    }
                }
            }
            .navigationTitle(category.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("닫기") { dismiss() }
                }
            }
        }
    }

    private var categoryBadge: some View {
        HStack(spacing: 10) {
            Text(category.emoji).font(.title2)
            VStack(alignment: .leading, spacing: 2) {
                Text(category.title)
                    .font(.normiHeadline)
                    .foregroundColor(category.color)
                Text(category.subtitle)
                    .font(.normiCaption)
                    .foregroundColor(.normiSubText)
            }
            Spacer()
        }
        .padding(16)
        .background(category.bgColor)
    }

    private func stationRow(_ station: String) -> some View {
        let isSelected = selectedStation == station
        return Button(action: { selectedStation = isSelected ? nil : station }) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(isSelected ? category.color : Color(.systemGray6))  // ✅ 다크모드 수정
                        .frame(width: 44, height: 44)
                    Image(systemName: isSelected ? "checkmark" : "tram")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(isSelected ? .white : category.color)
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text(station)
                        .font(.normiHeadline)
                        .foregroundColor(isSelected ? category.color : .primary)  // ✅ 다크모드 수정
                    Text("탭하여 선택")
                        .font(.normiCaption2)
                        .foregroundColor(.normiSubText)
                }
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(category.color)
                }
            }
            .padding(16)
            .background(isSelected ? category.bgColor : Color(.systemBackground))  // ✅ 다크모드 수정
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSelected ? category.color.opacity(0.4) : Color.clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.horizontal, 20)
    }
}
