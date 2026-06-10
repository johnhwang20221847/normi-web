// ============================================================
//  WeatherService.swift + WeatherViewModel.swift
//  OpenWeatherMap API 기반
//  Info.plist 에 WEATHER_API_KEY 키로 API 키를 저장하세요.
//  발급: https://openweathermap.org/api
// ============================================================

import Foundation
import CoreLocation

// MARK: - Service

final class WeatherService {
    static let shared = WeatherService()
    private init() {}

    private var apiKey: String {
        Bundle.main.object(forInfoDictionaryKey: "WEATHER_API_KEY") as? String
            ?? "YOUR_OPENWEATHERMAP_API_KEY"
    }
    private let base = "https://api.openweathermap.org/data/2.5"

    func fetch(lat: Double, lon: Double) async throws -> WeatherInfo {
        async let w = weather(lat: lat, lon: lon)
        async let a = air(lat: lat, lon: lon)
        let (wr, ar) = try await (w, a)
        let aq = ar.list.first
        return WeatherInfo(
            cityName:    wr.name,
            tempK:       wr.main.temp,
            feelsLikeK:  wr.main.feelsLike,
            tempMinK:    wr.main.tempMin,
            tempMaxK:    wr.main.tempMax,
            humidity:    wr.main.humidity,
            description: wr.weather.first?.description ?? "",
            iconCode:    wr.weather.first?.icon ?? "01d",
            windSpeed:   wr.wind.speed,
            aqi:         aq?.main.aqi ?? 1,
            pm25:        aq?.components.pm2_5 ?? 0
        )
    }

    private func weather(lat: Double, lon: Double) async throws -> WeatherResponse {
        var c = URLComponents(string: "\(base)/weather")!
        c.queryItems = [.init(name:"lat",value:"\(lat)"),
                        .init(name:"lon",value:"\(lon)"),
                        .init(name:"appid",value:apiKey),
                        .init(name:"lang",value:"kr")]
        let (d,_) = try await URLSession.shared.data(from: c.url!)
        return try JSONDecoder().decode(WeatherResponse.self, from: d)
    }

    private func air(lat: Double, lon: Double) async throws -> AirQualityResponse {
        var c = URLComponents(string: "\(base)/air_pollution")!
        c.queryItems = [.init(name:"lat",value:"\(lat)"),
                        .init(name:"lon",value:"\(lon)"),
                        .init(name:"appid",value:apiKey)]
        let (d,_) = try await URLSession.shared.data(from: c.url!)
        return try JSONDecoder().decode(AirQualityResponse.self, from: d)
    }
}

// MARK: - ViewModel

import SwiftUI

@MainActor
final class WeatherViewModel: NSObject, ObservableObject {
    @Published var info: WeatherInfo?
    @Published var isLoading = false
    @Published var error: String?

    private let locationManager = CLLocationManager()
    private var lastLoc: CLLocation?

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
    }

    func load() {
        isLoading = true
        locationManager.requestWhenInUseAuthorization()
        locationManager.requestLocation()
    }

    func refresh() {
        if let l = lastLoc { fetch(l) } else { load() }
    }

    private func fetch(_ loc: CLLocation) {
        Task {
            isLoading = true
            error = nil
            do {
                info = try await WeatherService.shared.fetch(
                    lat: loc.coordinate.latitude,
                    lon: loc.coordinate.longitude
                )
                // 날씨 기반 아침 알림 예약
                if let info {
                    NotificationManager.shared.scheduleMorningWeather(info: info)
                }
            } catch {
                self.error = "날씨 정보를 불러오지 못했습니다."
            }
            isLoading = false
        }
    }
}

extension WeatherViewModel: CLLocationManagerDelegate {
    nonisolated func locationManager(_ m: CLLocationManager, didUpdateLocations locs: [CLLocation]) {
        guard let loc = locs.last else { return }
        Task { @MainActor in
            self.lastLoc = loc
            self.fetch(loc)
        }
    }
    nonisolated func locationManager(_ m: CLLocationManager, didFailWithError e: Error) {
        // 서울 기본값
        let seoul = CLLocation(latitude: 37.5665, longitude: 126.9780)
        Task { @MainActor in self.fetch(seoul) }
    }
    nonisolated func locationManagerDidChangeAuthorization(_ m: CLLocationManager) {
        switch m.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways: m.requestLocation()
        case .denied:
            let seoul = CLLocation(latitude: 37.5665, longitude: 126.9780)
            Task { @MainActor in self.fetch(seoul) }
        default: break
        }
    }
}
