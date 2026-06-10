//
//  SplashView.swift
//  com.normi.app
//
//  Created by John Hwang on 5/27/26.
//

import SwiftUI

struct SplashView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @State private var isActive = false
    @State private var opacity  = 0.0
    @State private var scale    = 0.8

    var body: some View {
        if isActive {
            // 로그인 여부 관계없이 메인 앱 진입
            // 로그인 안 된 사용자도 홈/소풍/경로 접근 가능
            MainTabView()
                .environmentObject(authVM)
        } else {
            ZStack {
                Color.white.ignoresSafeArea()
                Image("SplashImage")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
                    .scaleEffect(scale)
                    .opacity(opacity)
            }
            .onAppear {
                withAnimation(.easeOut(duration: 0.8)) {
                    opacity = 1.0
                    scale   = 1.0
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        isActive = true
                    }
                }
            }
        }
    }
}
