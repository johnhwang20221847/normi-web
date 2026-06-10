// ============================================================
//  ContentView.swift
//  메인 탭 — 홈 / 소풍 / 경로 / 커뮤니티 / 마이
// ============================================================

import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @State private var selectedTab = 0
    @State private var showLogin   = false

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView(selectedTab: $selectedTab)
                .tabItem { Label("홈", systemImage: "house.fill") }
                .tag(0)

            OutingView()
                .tabItem { Label("소풍", systemImage: "figure.walk") }
                .tag(1)

            RouteSearchView()
                .tabItem { Label("경로", systemImage: "tram.fill") }
                .tag(2)

            // 커뮤니티는 로그인 필요
            Group {
                if authVM.isLoggedIn {
                    CommunityView()
                } else {
                    NeedLoginView(tabName: "커뮤니티") {
                        showLogin = true
                    }
                }
            }
            .tabItem { Label("커뮤니티", systemImage: "bubble.left.and.bubble.right.fill") }
            .tag(3)

            // 마이도 로그인 필요
            Group {
                if authVM.isLoggedIn {
                    ProfileView(
                        userUID: authVM.currentUser?.id ?? "",
                        nickname: authVM.currentUser?.nickname ?? "",
                        isMyProfile: true
                    )
                } else {
                    NeedLoginView(tabName: "마이") {
                        showLogin = true
                    }
                }
            }
            .tabItem { Label("마이", systemImage: "person.fill") }
            .tag(4)
        }
        .accentColor(.normiBlue)
        .sheet(isPresented: $showLogin) {
            LoginView()
                .environmentObject(authVM)
        }
        .onChange(of: authVM.isLoggedIn) { _, isLoggedIn in
            if isLoggedIn {
                showLogin = false
            }
        }
    }
}

// 로그인 유도 화면
struct NeedLoginView: View {
    let tabName: String
    let onLogin: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "lock.circle.fill")
                .font(.system(size: 70))
                .foregroundColor(.normiBlue.opacity(0.4))
            Text("\(tabName) 탭은\n로그인이 필요합니다")
                .font(.normiTitle2)
                .foregroundColor(.normiNavy)
                .multilineTextAlignment(.center)
            Button(action: onLogin) {
                Label("로그인 / 회원가입", systemImage: "person.fill")
            }
            .buttonStyle(NormiPrimaryButton())
            .frame(maxWidth: 240)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.normiGray)
    }
}
