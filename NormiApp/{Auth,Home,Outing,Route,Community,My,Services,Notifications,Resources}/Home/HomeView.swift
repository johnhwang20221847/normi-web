// ============================================================
//  HomeView.swift
//  화면 3 — 홈탭: 날씨 확인, 소풍 결정
//  와이어프레임: 날씨 카드 / 나들이 지수 / 지하철 운행 정보
//             / 소풍 떠나기 버튼 / 추천 소풍지
// ============================================================

import SwiftUI

struct HomeView: View {
    @Binding var selectedTab: Int
    @EnvironmentObject var authVM: AuthViewModel
    @StateObject private var weatherVM = WeatherViewModel()
    @State private var subwayStatus: SubwayStatus = .normal

    var body: some View {
        NavigationView {
            ZStack(alignment: .top) {
                Color.normiGray.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        // ① 인사말
                        greetingSection
                        // ② 날씨 카드 (wireframe 화면3 상단)
                        weatherSection
                        // ③ 나들이 지수 + 주의사항
                        if let info = weatherVM.info {
                            outingIndexCard(info)
                            tipsSection(info)
                        }
                        // ④ 지하철 운행 정보 (wireframe 화면3 하단)
                        subwayStatusCard
                        // ⑤ 소풍 떠나기 CTA (wireframe 화면3 버튼)
                        outingCTA
                        // ⑥ 추천 소풍지
                        recommendedSection
                        Spacer(minLength: 32)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("NORMI").font(.normiTitle2).foregroundColor(.normiNavy)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { weatherVM.refresh() } label: {
                        Image(systemName: "arrow.clockwise").foregroundColor(.normiBlue)
                    }
                }
            }
        }
        .onAppear { weatherVM.load() }
    }

    // MARK: - ① 인사말

    private var greetingSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text("안녕하세요, \(authVM.currentUser?.nickname ?? "어르신")님!")
                    .font(.normiTitle2)
                    .foregroundColor(.normiNavy)
                Text("오늘도 좋은 하루 되세요 😊")
                    .font(.normiBody)
                    .foregroundColor(.normiSubText)
            }
            Spacer()
            // 알림 아이콘
            ZStack(alignment: .topTrailing) {
                Image(systemName: "bell.fill")
                    .font(.title2)
                    .foregroundColor(.normiBlue)
                Circle().fill(Color.normiRed)
                    .frame(width: 8, height: 8)
                    .offset(x: 2, y: -2)
            }
        }
    }

    // MARK: - ② 날씨 카드

    @ViewBuilder
    private var weatherSection: some View {
        if weatherVM.isLoading {
            weatherLoadingCard
        } else if let info = weatherVM.info {
            weatherCard(info)
        } else if let err = weatherVM.error {
            weatherErrorCard(err)
        }
    }

    private var weatherLoadingCard: some View {
        HStack {
            Spacer()
            VStack(spacing: 10) {
                ProgressView().tint(.normiBlue).scaleEffect(1.2)
                Text("날씨 불러오는 중...").font(.normiCaption).foregroundColor(.normiSubText)
            }
            Spacer()
        }
        .padding(32)
        .normiCard()
    }

    private func weatherErrorCard(_ msg: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "wifi.exclamationmark").font(.largeTitle).foregroundColor(.normiSubText)
            Text(msg).font(.normiCaption).foregroundColor(.normiSubText).multilineTextAlignment(.center)
            Button("다시 시도") { weatherVM.refresh() }
                .font(.normiCaption.weight(.semibold)).foregroundColor(.normiBlue)
        }
        .padding(24).normiCard()
    }

    private func weatherCard(_ info: WeatherInfo) -> some View {
        VStack(spacing: 0) {
            // 상단: 날씨 메인
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("오늘의 날씨")
                        .font(.normiCaption.weight(.semibold))
                        .foregroundColor(.normiSubText)
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text(info.description.isEmpty ? "맑음" : info.description)
                            .font(.normiHeadline)
                            .foregroundColor(.normiNavy)
                    }
                    Text(info.tempText)
                        .font(.system(size: 52, weight: .thin, design: .rounded))
                        .foregroundColor(.normiNavy)
                    Text(info.rangeText)
                        .font(.normiCaption)
                        .foregroundColor(.normiSubText)
                }
                Spacer()
                Text(info.weatherEmoji)
                    .font(.system(size: 72))
            }
            .padding(20)

            Divider().padding(.horizontal, 16)

            // 하단: 세부 정보
            HStack(spacing: 0) {
                weatherDetail(icon:"humidity.fill",    label:"습도",   value:"\(info.humidity)%")
                Divider().frame(height: 40)
                weatherDetail(icon:"wind",             label:"풍속",   value:"\(String(format:"%.1f",info.windSpeed))m")
                Divider().frame(height: 40)
                weatherDetail(icon:"aqi.medium",      label:"미세먼지", value:info.aqiText)
                Divider().frame(height: 40)
                weatherDetail(icon:"thermometer",     label:"체감",   value:"\(info.feelsC)°")
            }
            .padding(.vertical, 14)
        }
        .normiCard(padding: 0)
    }

    private func weatherDetail(icon: String, label: String, value: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon).font(.caption).foregroundColor(.normiBlue)
            Text(value).font(.normiCaption.weight(.semibold)).foregroundColor(.normiText)
            Text(label).font(.normiCaption2).foregroundColor(.normiSubText)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - ③ 나들이 지수

    private func outingIndexCard(_ info: WeatherInfo) -> some View {
        HStack(spacing: 14) {
            Text(info.outingIndex.emoji)
                .font(.system(size: 32))
            VStack(alignment: .leading, spacing: 4) {
                Text("나들이 지수")
                    .font(.normiCaption)
                    .foregroundColor(.normiSubText)
                HStack(spacing: 8) {
                    Text(info.outingIndex.text)
                        .font(.normiHeadline)
                        .foregroundColor(Color(hex: info.outingIndex.color))
                    // 지수 바
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Color.normiGray).frame(height: 8)
                            Capsule()
                                .fill(Color(hex: info.outingIndex.color))
                                .frame(
                                    width: geo.size.width * indexRatio(info.outingIndex),
                                    height: 8
                                )
                        }
                    }
                    .frame(height: 8)
                }
            }
        }
        .normiCard()
    }

    private func indexRatio(_ idx: OutingIndex) -> CGFloat {
        switch idx { case .good: 0.9; case .fair: 0.55; case .bad: 0.2 }
    }

    // MARK: - 주의사항 팁

    private func tipsSection(_ info: WeatherInfo) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("오늘의 외출 체크리스트")
                .font(.normiHeadline)
                .foregroundColor(.normiNavy)

            ForEach(info.tips) { tip in
                HStack(spacing: 12) {
                    Text(tip.icon)
                        .font(.title3)
                        .frame(width: 44, height: 44)
                        .background(Color(hex: tip.level.color).opacity(0.1))
                        .cornerRadius(12)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(tip.title)
                            .font(.normiCaption.weight(.semibold))
                            .foregroundColor(Color(hex: tip.level.color))
                        Text(tip.detail)
                            .font(.normiCaption)
                            .foregroundColor(.normiSubText)
                    }
                    Spacer()
                }
                .normiCard()
            }
        }
    }

    // MARK: - ④ 지하철 운행 정보 (wireframe 화면3)

    private var subwayStatusCard: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(subwayStatus == .normal
                          ? Color.normiGreen.opacity(0.12)
                          : Color.normiRed.opacity(0.12))
                    .frame(width: 44, height: 44)
                Image(systemName: subwayStatus == .normal ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                    .foregroundColor(subwayStatus == .normal ? .normiGreen : .normiRed)
                    .font(.title3)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("지하철 운행 정보")
                    .font(.normiCaption.weight(.semibold))
                    .foregroundColor(.normiSubText)
                Text(subwayStatus.message)
                    .font(.normiHeadline)
                    .foregroundColor(subwayStatus == .normal ? .normiGreen : .normiRed)
                Text(subwayStatus == .normal ? "노선별 문의는 경로 탭을 이용하세요." : "우회 경로를 확인하세요.")
                    .font(.normiCaption)
                    .foregroundColor(.normiSubText)
            }
            Spacer()
        }
        .normiCard()
    }

    // MARK: - ⑤ 소풍 떠나기 CTA (wireframe 화면3 큰 버튼)

    private var outingCTA: some View {
        VStack(spacing: 12) {
            Text("오늘 어디로 떠나볼까요?")
                .font(.normiHeadline)
                .foregroundColor(.normiNavy)
            Button(action: { selectedTab = 1 }) {
                HStack(spacing: 10) {
                    Image(systemName: "figure.walk.departure")
                    Text("소풍 떠나기")
                }
            }
            .buttonStyle(NormiPrimaryButton())
        }
        .padding(20)
        .background(
            LinearGradient(colors: [Color(hex:"#E8F1FF"), Color(hex:"#D4E6FF")],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
        )
        .cornerRadius(20)
    }

    // MARK: - ⑥ 추천 소풍지

    private let recommendedPlaces: [RecommendedPlace] = [
        .init(name: "도봉산역",    desc: "자연과 함께하는 힐링\n지하철 1호선",  emoji: "⛰️", line: "1호선"),
        .init(name: "소요산역",    desc: "계곡과 단풍이 아름다운\n경원선 종착역", emoji: "🌲", line: "경원선"),
        .init(name: "인천시장역",  desc: "맛있는 시장 구경\n인천 1호선",      emoji: "🏮", line: "인천1호선"),
        .init(name: "온양온천역",  desc: "피로를 풀어주는 온천\n장항선",       emoji: "♨️", line: "장항선"),
    ]

    private var recommendedSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("추천 소풍지")
                .font(.normiHeadline)
                .foregroundColor(.normiNavy)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(recommendedPlaces) { place in
                        recommendCard(place)
                    }
                }
            }
        }
    }

    private func recommendCard(_ place: RecommendedPlace) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(place.emoji).font(.system(size: 36))
            Text(place.name)
                .font(.normiCaption.weight(.bold))
                .foregroundColor(.normiNavy)
            Text(place.desc)
                .font(.normiCaption2)
                .foregroundColor(.normiSubText)
                .lineSpacing(3)
            Spacer()
            NormiBadge(text: place.line, color: .normiBlue)
        }
        .padding(14)
        .frame(width: 140, height: 160)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.normiNavy.opacity(0.06), radius: 6, y: 2)
    }
}

// MARK: - Helpers

enum SubwayStatus {
    case normal, disruption
    var message: String {
        switch self { case .normal: "정상 운행 중"; case .disruption: "운행 장애 발생" }
    }
}

struct RecommendedPlace: Identifiable {
    let id = UUID()
    let name: String
    let desc: String
    let emoji: String
    let line: String
}
