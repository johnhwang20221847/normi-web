// ============================================================
//  RouteDetailView.swift + TrainTrackingView.swift
//  와이어프레임 화면 6 — 경로 안내 상세 / 실시간 탑승 추적
// ============================================================

import SwiftUI

// MARK: - Route Detail (경로 상세)

struct RouteDetailView: View {
    let route: SubwayRoute
    @ObservedObject var vm: RouteViewModel
    @State private var showTracking   = false
    @State private var showAlarmAlert = false

    var body: some View {
        ZStack {
            Color.normiGray.ignoresSafeArea()
            VStack(spacing: 0) {
                // 요약 바
                summaryBar
                // 구간 타임라인
                ScrollView { segmentTimeline.padding(20) }
                // 하단 버튼
                actionBar
            }
        }
        .navigationTitle("경로 안내")
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(isPresented: $showTracking) {
            TrainTrackingView(route: route, vm: vm)
        }
        .alert("하차 알림 설정", isPresented: $showAlarmAlert) {
            Button("설정") {
                let last = route.allStations.last?.name ?? "도착역"
                NotificationManager.shared.scheduleExitAlarm(station: last)
            }
            Button("취소", role: .cancel) {}
        } message: {
            if let last = route.allStations.last {
                Text("\(last.name) 2정거장 전에\n알림을 보내드릴게요.")
            }
        }
    }

    // MARK: - 요약 바

    private var summaryBar: some View {
        HStack(spacing: 0) {
            summaryItem("⏱", route.timeText,  "소요시간")
            Divider().frame(height: 44)
            summaryItem("💰", route.fareText,  "요금")
            Divider().frame(height: 44)
            summaryItem("🚶", "\(route.totalWalk)m","도보")
            Divider().frame(height: 44)
            let transfers = route.segments.filter { $0.type == .subway }.count - 1
            summaryItem("🔄", "\(max(0, transfers))회", "환승")
        }
        .padding(.vertical, 14)
        .background(Color.white)
        .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
    }

    private func summaryItem(_ icon: String, _ value: String, _ label: String) -> some View {
        VStack(spacing: 3) {
            Text(icon)
            Text(value).font(.normiCaption.weight(.bold)).foregroundColor(.normiNavy)
            Text(label).font(.normiCaption2).foregroundColor(.normiSubText)
        }.frame(maxWidth: .infinity)
    }

    // MARK: - 구간 타임라인

    private var segmentTimeline: some View {
        VStack(spacing: 0) {
            ForEach(route.segments) { seg in
                segRow(seg)
            }
        }
    }

    private func segRow(_ seg: RouteSegment) -> some View {
        HStack(alignment: .top, spacing: 16) {
            // 타임라인 선
            VStack(spacing: 0) {
                Circle()
                    .fill(seg.type == .subway ? Color(hex: seg.lineColor) : Color.normiSubText)
                    .frame(width: 14, height: 14)
                Rectangle()
                    .fill(seg.type == .subway ? Color(hex: seg.lineColor) : Color.normiSubText.opacity(0.3))
                    .frame(width: 3)
                    .frame(minHeight: 60)
            }
            // 내용
            VStack(alignment: .leading, spacing: 8) {
                if seg.type == .subway {
                    subwaySegment(seg)
                } else {
                    walkSegment(seg)
                }
            }
            .padding(.bottom, 16)
        }
    }

    private func subwaySegment(_ seg: RouteSegment) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(seg.lineName)
                    .font(.normiCaption2.weight(.bold)).foregroundColor(.white)
                    .padding(.horizontal, 10).padding(.vertical, 4)
                    .background(Color(hex: seg.lineColor))
                    .cornerRadius(8)
                Spacer()
                Text("\(seg.sectionMin)분")
                    .font(.normiCaption).foregroundColor(.normiSubText)
            }
            Text(seg.startName).font(.normiHeadline).foregroundColor(.normiNavy)

            if seg.stops.count > 2 {
                DisclosureGroup {
                    ForEach(seg.stops) { s in
                        HStack(spacing: 8) {
                            Circle().stroke(Color(hex: seg.lineColor), lineWidth: 2).frame(width: 8, height: 8)
                            Text(s.name).font(.normiCaption).foregroundColor(.normiSubText)
                        }
                        .padding(.leading, 4).padding(.vertical, 2)
                    }
                } label: {
                    Text("중간역 \(seg.stops.count - 2)개")
                        .font(.normiCaption.weight(.semibold))
                        .foregroundColor(Color(hex: seg.lineColor))
                }
            }
            Text(seg.endName).font(.normiHeadline).foregroundColor(.normiNavy)
        }
    }

    private func walkSegment(_ seg: RouteSegment) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "figure.walk").foregroundColor(.normiSubText)
            Text("도보 \(seg.walkM)m · \(seg.sectionMin)분")
                .font(.normiBody).foregroundColor(.normiSubText)
        }
    }

    // MARK: - 하단 버튼

    private var actionBar: some View {
        VStack(spacing: 0) {
            Divider()
            HStack(spacing: 12) {
                Button(action: { showTracking = true }) {
                    Label("탑승 추적 시작", systemImage: "location.fill")
                }
                .buttonStyle(NormiPrimaryButton())

                Button(action: { showAlarmAlert = true }) {
                    Label("하차 알림", systemImage: "bell.fill")
                        .font(.normiHeadline)
                        .foregroundColor(.normiBlue)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.normiSky)
                        .cornerRadius(14)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(Color.white)
    }
}

// MARK: - Train Tracking View (실시간 탑승 추적)

struct TrainTrackingView: View {
    let route: SubwayRoute
    @ObservedObject var vm: RouteViewModel
    @Environment(\.dismiss) var dismiss
    @State private var appeared = false

    private var allStops: [StationStop] { route.allStations }

    var body: some View {
        NavigationView {
            ZStack {
                Color.normiGray.ignoresSafeArea()
                VStack(spacing: 0) {
                    // 진행 현황 카드
                    progressCard
                    // 정거장 리스트
                    stationList
                }
            }
            .navigationTitle("탑승 추적 중")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("종료") { vm.stopTracking(); dismiss() }
                        .foregroundColor(.normiRed)
                }
            }
        }
        .onAppear {
            if !appeared { vm.startTracking(route); appeared = true }
        }
        .alert("하차 준비하세요!", isPresented: $vm.showExitAlert) {
            Button("확인") { vm.showExitAlert = false }
        } message: {
            Text("\(allStops.last?.name ?? "도착역")까지\n\(vm.stopsLeft)정거장 남았습니다.\n내리실 준비를 해주세요.")
        }
    }

    // MARK: - 진행 현황

    private var progressCard: some View {
        VStack(spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("현재 위치").font(.normiCaption).foregroundColor(.normiSubText)
                    Text(allStops.indices.contains(vm.currentIdx)
                         ? allStops[vm.currentIdx].name : "파악 중...")
                        .font(.normiTitle2).foregroundColor(.normiNavy)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text("남은 정거장").font(.normiCaption).foregroundColor(.normiSubText)
                    Text("\(vm.stopsLeft)개").font(.normiTitle2).foregroundColor(.normiBlue)
                }
            }

            // 진행 바
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.normiGray).frame(height: 8)
                    let ratio = allStops.isEmpty ? 0.0
                        : CGFloat(vm.currentIdx) / CGFloat(allStops.count - 1)
                    Capsule()
                        .fill(
                            LinearGradient(colors: [.normiBlue, Color(hex:"#74B3FF")],
                                           startPoint: .leading, endPoint: .trailing)
                        )
                        .frame(width: max(10, geo.size.width * ratio), height: 8)
                        .animation(.easeInOut(duration: 0.5), value: vm.currentIdx)
                }
            }
            .frame(height: 8)

            HStack {
                Text(allStops.first?.name ?? "출발")
                    .font(.normiCaption2).foregroundColor(.normiSubText)
                Spacer()
                Text(allStops.last?.name ?? "도착")
                    .font(.normiCaption2).foregroundColor(.normiSubText)
            }

            if vm.stopsLeft <= 2 && vm.stopsLeft > 0 {
                HStack(spacing: 6) {
                    Image(systemName: "bell.fill").foregroundColor(.normiOrange)
                    Text("곧 도착합니다! 내리실 준비를 해주세요.")
                        .font(.normiCaption.weight(.semibold)).foregroundColor(.normiOrange)
                }
                .padding(10)
                .background(Color.normiOrange.opacity(0.1))
                .cornerRadius(10)
            }
        }
        .normiCard()
        .padding(16)
    }

    // MARK: - 정거장 리스트

    private var stationList: some View {
        ScrollView {
            LazyVStack(spacing: 0, pinnedViews: []) {
                ForEach(Array(allStops.enumerated()), id: \.element.id) { idx, stop in
                    HStack(spacing: 16) {
                        // 상태 원
                        ZStack {
                            Circle()
                                .fill(idx < vm.currentIdx ? Color.normiBlue.opacity(0.3)
                                      : idx == vm.currentIdx ? Color.normiBlue : Color.normiGray)
                                .frame(width: 28, height: 28)
                            if idx == vm.currentIdx {
                                Circle().fill(Color.white).frame(width: 10, height: 10)
                            } else if idx < vm.currentIdx {
                                Image(systemName: "checkmark").font(.caption2.weight(.bold))
                                    .foregroundColor(.normiBlue)
                            }
                        }
                        Text(stop.name)
                            .font(idx == vm.currentIdx ? .normiHeadline : .normiBody)
                            .foregroundColor(idx == vm.currentIdx ? .normiBlue
                                             : idx < vm.currentIdx ? .normiSubText : .normiText)
                        Spacer()
                        if idx == vm.currentIdx {
                            NormiBadge(text: "현재 위치", color: .normiBlue)
                        } else if idx == allStops.count - 1 {
                            NormiBadge(text: "도착역", color: .normiGreen)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(idx == vm.currentIdx ? Color.normiSky : Color.clear)

                    if idx < allStops.count - 1 {
                        HStack(spacing: 0) {
                            Spacer().frame(width: 20 + 14)
                            Rectangle().fill(Color.normiGray).frame(width: 2, height: 20)
                            Spacer()
                        }
                    }
                }
            }
            .padding(.bottom, 40)
        }
    }
}
