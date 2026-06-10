// ============================================================
//  RouteViewModel.swift
// ============================================================

import Foundation
import CoreLocation

@MainActor
final class RouteViewModel: NSObject, ObservableObject {
    // 검색
    @Published var depText   = ""
    @Published var arrText   = ""
    @Published var depCoord: CLLocationCoordinate2D?
    @Published var arrCoord: CLLocationCoordinate2D?
    @Published var depResults: [(String, CLLocationCoordinate2D)] = []
    @Published var arrResults: [(String, CLLocationCoordinate2D)] = []

    // 경로
    @Published var routes: [SubwayRoute] = []
    @Published var isLoadingRoute = false
    @Published var routeError: String?

    // 탑승 추적
    @Published var isTracking = false
    @Published var currentIdx = 0
    @Published var stopsLeft  = 0
    @Published var showExitAlert = false

    private let loc = CLLocationManager()
    private var userLoc: CLLocationCoordinate2D?
    private var trackTimer: Timer?
    var selectedRoute: SubwayRoute?

    override init() {
        super.init()
        loc.delegate = self
        loc.desiredAccuracy = kCLLocationAccuracyBest
    }

    // MARK: - Preset (소풍 탭에서 넘어올 때)

    convenience init(presetArrival: String) {
        self.init()
        arrText = presetArrival
        Task { await searchArr() }
    }

    // MARK: - Autocomplete

    func searchDep() async {
        guard depText.count >= 2 else { depResults = []; return }
        depResults = (try? await SubwayService.shared.stationSearch(name: depText)) ?? []
    }

    func searchArr() async {
        guard arrText.count >= 2 else { arrResults = []; return }
        arrResults = (try? await SubwayService.shared.stationSearch(name: arrText)) ?? []
    }

    func selectDep(_ r: (String, CLLocationCoordinate2D)) { depText = r.0; depCoord = r.1; depResults = [] }
    func selectArr(_ r: (String, CLLocationCoordinate2D)) { arrText = r.0; arrCoord = r.1; arrResults = [] }

    func swap() {
        Swift.swap(&depText, &arrText)
        Swift.swap(&depCoord, &arrCoord)
    }

    // MARK: - Route Search

    func findRoute() async {
        guard let s = depCoord, let e = arrCoord else {
            routeError = "출발역과 도착역을 선택해주세요."; return
        }
        isLoadingRoute = true; routeError = nil
        do {
            routes = try await SubwayService.shared.searchRoute(
                sx: s.longitude, sy: s.latitude,
                ex: e.longitude, ey: e.latitude
            )
        } catch { routeError = "경로를 찾지 못했습니다. 다시 시도해주세요." }
        isLoadingRoute = false
    }

    // MARK: - Train Tracking

    func startTracking(_ route: SubwayRoute) {
        selectedRoute = route
        currentIdx = 0; isTracking = true
        updateRemain(route)
        loc.requestWhenInUseAuthorization()
        loc.startUpdatingLocation()
        trackTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.updateFromLocation(route) }
        }
    }

    func stopTracking() {
        isTracking = false
        loc.stopUpdatingLocation()
        trackTimer?.invalidate()
        trackTimer = nil
    }

    private func updateFromLocation(_ route: SubwayRoute) {
        guard let ul = userLoc else { return }
        let all = route.allStations
        guard !all.isEmpty else { return }
        var best = (idx: currentIdx, dist: Double.infinity)
        for (i, st) in all.enumerated() {
            let d = CLLocation(latitude: ul.latitude, longitude: ul.longitude)
                .distance(from: CLLocation(latitude: st.lat, longitude: st.lon))
            if d < best.dist { best = (i, d) }
        }
        if best.idx != currentIdx {
            currentIdx = best.idx
            updateRemain(route)
            if stopsLeft <= 2 && stopsLeft > 0 {
                showExitAlert = true
                let last = route.allStations.last?.name ?? "도착역"
                NotificationManager.shared.sendExitAlert(station: last, stops: stopsLeft)
            }
        }
    }

    private func updateRemain(_ route: SubwayRoute) {
        stopsLeft = max(0, route.allStations.count - 1 - currentIdx)
    }
}

extension RouteViewModel: CLLocationManagerDelegate {
    nonisolated func locationManager(_ m: CLLocationManager, didUpdateLocations ls: [CLLocation]) {
        guard let l = ls.last else { return }
        Task { @MainActor in
            self.userLoc = l.coordinate
            if let r = self.selectedRoute { self.updateFromLocation(r) }
        }
    }
    nonisolated func locationManager(_ m: CLLocationManager, didFailWithError e: Error) {}
}
