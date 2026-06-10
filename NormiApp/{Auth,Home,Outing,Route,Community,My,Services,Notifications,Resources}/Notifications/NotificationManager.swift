// ============================================================
//  NotificationManager.swift
//  와이어프레임 화면1 — 아침 날씨 알림
//  하차 2정거장 전 알림
// ============================================================

import Foundation
import UserNotifications

final class NotificationManager {
    static let shared = NotificationManager()
    private init() {}

    private let center = UNUserNotificationCenter.current()

    // MARK: - Permission

    func requestPermission() {
        center.requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }

    // MARK: - 아침 날씨 알림 (화면1 — 07:30 push)

    func scheduleMorningWeather(info: WeatherInfo) {
        center.removePendingNotificationRequests(withIdentifiers: ["morningWeather"])

        let content        = UNMutableNotificationContent()
        content.title      = "오늘 날씨 알림 \(info.weatherEmoji)"
        content.body       = "\(info.tempText)  \(info.description)\n\(info.tips.first?.title ?? "") — \(info.tips.first?.detail ?? "")"
        content.sound      = .default

        var comps          = DateComponents()
        comps.hour         = 7
        comps.minute       = 30

        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
        let req     = UNNotificationRequest(identifier: "morningWeather",
                                            content: content, trigger: trigger)
        center.add(req)
    }

    // MARK: - 하차 알림 (탑승 추적 중 실시간)

    func sendExitAlert(station: String, stops: Int) {
        let content    = UNMutableNotificationContent()
        content.title  = "⚠️ 곧 내리세요!"
        content.body   = "\(station)까지 \(stops)정거장 남았습니다. 내리실 준비를 해주세요."
        content.sound  = .defaultCritical

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let req     = UNNotificationRequest(identifier: "exitAlert_\(UUID())",
                                            content: content, trigger: trigger)
        center.add(req)
    }

    // MARK: - 내일 알림 받기 (화면9)

    func scheduleTomorrowReminder() {
        center.removePendingNotificationRequests(withIdentifiers: ["tomorrowReminder"])

        let content   = UNMutableNotificationContent()
        content.title = "🌅 좋은 아침이에요!"
        content.body  = "오늘도 즐거운 소풍 되세요. 날씨를 확인하고 출발해 보세요 😊"
        content.sound = .default

        var comps   = DateComponents()
        comps.hour  = 8
        comps.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
        let req     = UNNotificationRequest(identifier: "tomorrowReminder",
                                            content: content, trigger: trigger)
        center.add(req)
    }

    // MARK: - 하차 예약 알림 (경로 설정 시)

    func scheduleExitAlarm(station: String) {
        center.removePendingNotificationRequests(withIdentifiers: ["scheduledExit"])

        let content   = UNMutableNotificationContent()
        content.title = "🚉 하차 준비"
        content.body  = "\(station)에 곧 도착합니다. 내리실 준비를 해주세요."
        content.sound = .default

        // 실제로는 위치 기반으로 발송; 여기서는 예시로 1분 후
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 60, repeats: false)
        let req     = UNNotificationRequest(identifier: "scheduledExit",
                                            content: content, trigger: trigger)
        center.add(req)
    }
}
