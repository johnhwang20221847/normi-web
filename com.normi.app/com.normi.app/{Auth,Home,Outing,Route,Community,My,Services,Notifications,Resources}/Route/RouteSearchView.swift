// ============================================================
//  RouteSearchView.swift
//  화면 6 — 경로 탭 + 와이어프레임 경로 안내 화면
// ============================================================

import SwiftUI
import CoreLocation

struct RouteSearchView: View {
    var presetArrival: String = ""
    @StateObject private var vm: RouteViewModel

    init(presetArrival: String = "") {
        self.presetArrival = presetArrival
        _vm = StateObject(wrappedValue: RouteViewModel())
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()  // ✅ 다크모드 수정

                VStack(spacing: 0) {
                    searchPanel
                        .padding(16)
                        .background(Color(.systemBackground))          // ✅ 다크모드 수정
                        .shadow(color: Color(.label).opacity(0.05), radius: 6, y: 3)  // ✅ 다크모드 수정

                    if vm.isLoadingRoute {
                        Spacer()
                        VStack(spacing: 14) {
                            ProgressView().scaleEffect(1.2)
                            Text("최적 경로를 탐색하는 중...")
                                .font(.normiBody)
                                .foregroundColor(.normiSubText)
                        }
                        Spacer()
                    } else if !vm.routes.isEmpty {
                        routeResultList
                    } else {
                        emptyState
                    }
                }
            }
            .navigationTitle("경로 찾기")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            if !presetArrival.isEmpty {
                vm.arrText = presetArrival
                Task { await vm.searchArr() }
            }
        }
    }

    // MARK: - 검색 패널

    private var searchPanel: some View {
        VStack(spacing: 10) {
            // 출발 필드
            VStack(alignment: .leading, spacing: 4) {
                stationField(
                    icon: "circle.fill",
                    color: .normiGreen,
                    placeholder: "출발역",
                    text: $vm.depText
                ) {
                    Task { await vm.searchDep() }
                }
                if !vm.depResults.isEmpty {
                    autocompleteList(vm.depResults) { vm.selectDep($0) }
                }
            }

            // 스왑 버튼
            HStack {
                Rectangle()
                    .fill(Color(.systemGray5))          // ✅ 다크모드 수정
                    .frame(height: 1)
                Button(action: vm.swap) {
                    Image(systemName: "arrow.up.arrow.down")
                        .foregroundColor(.normiBlue)
                        .frame(width: 36, height: 36)
                        .background(Color.normiSky)
                        .clipShape(Circle())
                }
                Rectangle()
                    .fill(Color(.systemGray5))          // ✅ 다크모드 수정
                    .frame(height: 1)
            }

            // 도착 필드
            VStack(alignment: .leading, spacing: 4) {
                stationField(
                    icon: "mappin.circle.fill",
                    color: .normiRed,
                    placeholder: "도착역",
                    text: $vm.arrText
                ) {
                    Task { await vm.searchArr() }
                }
                if !vm.arrResults.isEmpty {
                    autocompleteList(vm.arrResults) { vm.selectArr($0) }
                }
            }

            // 탐색 버튼
            Button(action: { Task { await vm.findRoute() } }) {
                HStack {
                    Image(systemName: "magnifyingglass")
                    Text("경로 탐색")
                }
            }
            .buttonStyle(NormiPrimaryButton())
            .disabled(vm.depText.isEmpty || vm.arrText.isEmpty)
            .opacity(vm.depText.isEmpty || vm.arrText.isEmpty ? 0.5 : 1)

            if let err = vm.routeError {
                Label(err, systemImage: "exclamationmark.triangle.fill")
                    .font(.normiCaption)
                    .foregroundColor(.normiRed)
            }
        }
    }

    private func stationField(
        icon: String,
        color: Color,
        placeholder: String,
        text: Binding<String>,
        onChange: @escaping () -> Void
    ) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon).foregroundColor(color)
            TextField(placeholder, text: text)
                .onChange(of: text.wrappedValue) { _ in onChange() }
        }
        .padding(12)
        .background(Color(.systemGray6))                // ✅ 다크모드 수정
        .cornerRadius(12)
    }

    private func autocompleteList(
        _ results: [(String, CLLocationCoordinate2D)],
        onSelect: @escaping ((String, CLLocationCoordinate2D)) -> Void
    ) -> some View {
        VStack(spacing: 0) {
            ForEach(results.prefix(5), id: \.0) { r in
                Button(action: { onSelect(r) }) {
                    HStack {
                        Image(systemName: "tram").foregroundColor(.normiSubText)
                        Text(r.0).foregroundColor(.primary)          // ✅ 다크모드 수정
                        Spacer()
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                }
                Divider()
            }
        }
        .background(Color(.systemBackground))           // ✅ 다크모드 수정
        .cornerRadius(10)
        .shadow(color: Color(.label).opacity(0.07), radius: 4, y: 2)  // ✅ 다크모드 수정
    }

    // MARK: - 경로 목록

    private var routeResultList: some View {
        ScrollView {
            VStack(spacing: 12) {
                HStack(spacing: 8) {
                    ForEach(["최적 경로", "최소 환승", "빠른 하차"], id: \.self) { label in
                        Text(label)
                            .font(.normiCaption.weight(.semibold))
                            .foregroundColor(.normiBlue)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.normiSky)
                            .cornerRadius(20)
                    }
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)

                ForEach(Array(vm.routes.enumerated()), id: \.element.id) { i, route in
                    NavigationLink(destination: RouteDetailView(route: route, vm: vm)) {
                        routeCard(route, rank: i + 1)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.horizontal, 16)
                }
            }
            .padding(.bottom, 20)
        }
    }

    private func routeCard(_ route: SubwayRoute, rank: Int) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("경로 \(rank)")
                    .font(.normiCaption2.weight(.bold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(rank == 1 ? Color.normiBlue : Color(.systemGray6))  // ✅ 다크모드 수정
                    .foregroundColor(rank == 1 ? .white : .normiSubText)
                    .cornerRadius(6)
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(route.timeText)
                        .font(.normiTitle2)
                        .foregroundColor(.normiNavy)
                    Text(route.fareText)
                        .font(.normiCaption)
                        .foregroundColor(.normiSubText)
                }
            }

            // 노선 배지
            HStack(spacing: 6) {
                ForEach(route.segments.filter { $0.type == .subway }) { seg in
                    Text(seg.lineName)
                        .font(.normiCaption2.weight(.bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(hex: seg.lineColor))
                        .cornerRadius(6)
                }
                if route.totalWalk > 0 {
                    Label("\(route.totalWalk)m", systemImage: "figure.walk")
                        .font(.normiCaption2)
                        .foregroundColor(.normiSubText)
                }
            }

            // 출발 → 도착
            Text("\(route.allStations.first?.name ?? "출발") → \(route.allStations.last?.name ?? "도착")")
                .font(.normiCaption)
                .foregroundColor(.normiSubText)
        }
        .normiCard()
    }

    // MARK: - Empty

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "tram.circle")
                .font(.system(size: 70))
                .foregroundColor(.normiBlue.opacity(0.25))
            Text("출발역과 도착역을 입력하고\n경로를 탐색해 보세요")
                .font(.normiBody)
                .foregroundColor(.normiSubText)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
            Spacer()
        }
    }
}
