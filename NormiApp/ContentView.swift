// ============================================================
//  ContentView.swift
//  메인 탭 — 홈 / 소풍 / 경로 / 커뮤니티 / 마이
// ============================================================

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            // 1. 홈
            HomeView(selectedTab: $selectedTab)
                .tabItem {
                    Label("홈", systemImage: selectedTab == 0 ? "house.fill" : "house")
                }
                .tag(0)

            // 2. 소풍
            OutingView()
                .tabItem {
                    Label("소풍", systemImage: selectedTab == 1 ? "figure.walk.departure" : "figure.walk")
                }
                .tag(1)

            // 3. 경로
            RouteSearchView()
                .tabItem {
                    Label("경로", systemImage: selectedTab == 2 ? "tram.fill" : "tram")
                }
                .tag(2)

            // 4. 커뮤니티
            CommunityView()
                .tabItem {
                    Label("커뮤니티", systemImage: selectedTab == 3 ? "bubble.left.and.bubble.right.fill" : "bubble.left.and.bubble.right")
                }
                .tag(3)

            // 5. 마이
            ProfileView()
                .tabItem {
                    Label("마이", systemImage: selectedTab == 4 ? "person.fill" : "person")
                }
                .tag(4)
        }
        .accentColor(.normiBlue)
    }
}
