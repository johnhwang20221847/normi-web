// ============================================================
//  NormiApp.swift
//  어르신의 지하철 소풍을 돕는 동반자, 노르미
//
//  Firebase 연동:
//  1. Firebase Console(https://console.firebase.google.com)에서 프로젝트 생성
//  2. iOS 앱 추가 → GoogleService-Info.plist 다운로드
//  3. 이 파일과 같은 폴더에 GoogleService-Info.plist 추가 (Xcode Target에 포함)
//  4. 터미널에서 `pod install` 실행
// ============================================================

import SwiftUI
import Firebase
import UserNotifications

@main
struct NormiApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var authVM = AuthViewModel()

    var body: some Scene {
        WindowGroup {
            SplashView()
                .environmentObject(authVM)
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        FirebaseApp.configure()
        NotificationManager.shared.requestPermission()
        return true
    }
}
