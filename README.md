# 노르미 (NORMI) — Xcode 배포 세팅 가이드

> 어르신의 지하철 소풍을 돕는 동반자

---

## 📁 프로젝트 파일 구조

```
NormiApp/
├── NormiApp.swift              # 앱 진입점 (Firebase 초기화)
├── ContentView.swift           # 5탭 메인 뷰
├── Info.plist                  # 권한·API 키 설정
│
├── Auth/
│   ├── UserModel.swift         # 사용자 데이터 모델
│   ├── AuthViewModel.swift     # Firebase Auth 로그인/회원가입
│   ├── LoginView.swift         # 로그인 화면
│   └── SignUpView.swift        # 회원가입 화면
│
├── Home/
│   ├── WeatherModels.swift     # 날씨 데이터 모델
│   ├── WeatherService.swift    # OpenWeatherMap API + ViewModel
│   └── HomeView.swift          # 홈탭 (날씨·나들이 지수·소풍 버튼)
│
├── Outing/
│   └── OutingView.swift        # 소풍탭 (4 카테고리 + 역 선택)
│
├── Route/
│   ├── RouteModels.swift       # 경로 데이터 모델 + SubwayService
│   ├── RouteViewModel.swift    # 경로 탐색 + 탑승 추적
│   ├── RouteSearchView.swift   # 경로 탐색 화면
│   └── RouteDetailView.swift   # 경로 상세 + 탑승 추적 화면
│
├── Community/
│   ├── PostModel.swift         # 게시글·댓글 모델 (Firestore)
│   ├── PostViewModel.swift     # 글 쓰기·좋아요·댓글 (Firestore+Storage)
│   ├── CommunityView.swift     # 커뮤니티 피드
│   ├── CreatePostView.swift    # 글 작성 (사진·텍스트·역)
│   └── PostDetailView.swift    # 게시글 상세 + 댓글
│
├── My/
│   └── ProfileView.swift       # 마이탭 + 프로필 수정 + 로그아웃
│
├── Notifications/
│   └── NotificationManager.swift # 날씨 알림·하차 알림
│
└── Resources/
    └── DesignSystem.swift      # 색상·폰트·공통 스타일
```

---

## 🔧 1단계 — Xcode 프로젝트 생성

1. Xcode → **File → New → Project**
2. **App** 템플릿 선택
3. 설정:
   - Product Name: `NormiApp`
   - Bundle Identifier: `com.normi.app` (원하는 ID 사용 가능)
   - Interface: **SwiftUI**
   - Language: **Swift**
   - Minimum Deployments: **iOS 16.0**
4. 위에서 작성된 모든 `.swift` 파일을 프로젝트 폴더로 복사 후 Xcode에서 **Add Files** 로 추가

---

## 🔥 2단계 — Firebase 설정

### 2-1. Firebase 프로젝트 생성
1. [Firebase Console](https://console.firebase.google.com) 접속
2. **새 프로젝트 만들기** → 프로젝트 이름: `normi-app`
3. Google Analytics 선택 후 완료

### 2-2. iOS 앱 등록
1. Firebase Console → 프로젝트 설정 → iOS 앱 추가
2. Bundle ID 입력: `com.normi.app`
3. **GoogleService-Info.plist** 다운로드
4. Xcode 프로젝트 루트에 드래그 앤 드롭 (Target Membership 체크 확인!)

### 2-3. Firebase 서비스 활성화
Firebase Console에서 아래 서비스를 **순서대로** 활성화:

| 서비스 | 위치 | 설정 |
|--------|------|------|
| Authentication | Build → Authentication | 이메일/비밀번호 로그인 활성화 |
| Firestore | Build → Firestore Database | 프로덕션 모드로 생성 (서울 리전: `asia-northeast3`) |
| Storage | Build → Storage | 기본 버킷 생성 |
| Messaging | 자동 활성화 | — |

### 2-4. 보안 규칙 적용
- **Firestore**: Console → Firestore → 규칙 탭 → `firestore.rules` 내용 붙여넣기
- **Storage**: Console → Storage → 규칙 탭 → `storage.rules` 내용 붙여넣기

---

## 📦 3단계 — CocoaPods 설치

터미널에서 프로젝트 폴더로 이동 후:

```bash
# CocoaPods 미설치 시
sudo gem install cocoapods

# 의존성 설치 (Podfile 있는 폴더에서)
pod install

# 이후 반드시 .xcworkspace 파일로 열기!
open NormiApp.xcworkspace
```

---

## 🌤️ 4단계 — API 키 발급 및 설정

### OpenWeatherMap (날씨)
1. [openweathermap.org](https://openweathermap.org/api) 회원가입
2. API Keys 탭 → API 키 복사
3. 무료 플랜으로 충분 (1분 60회 호출)

### ODsay (대중교통 경로)
1. [lab.odsay.com](https://lab.odsay.com) 회원가입
2. 내 애플리케이션 → API 키 복사
3. 무료 플랜: 1일 1,000회

### Info.plist에 키 입력
```xml
<key>WEATHER_API_KEY</key>
<string>발급받은_OpenWeatherMap_키</string>

<key>ODSAY_API_KEY</key>
<string>발급받은_ODsay_키</string>
```

---

## 📱 5단계 — Xcode 빌드 설정

### Signing & Capabilities
1. Xcode → **Signing & Capabilities** 탭
2. Team 선택 (Apple Developer 계정 필요)
3. Bundle Identifier 확인: `com.normi.app`

### 필수 Capabilities 추가 (+ 버튼)
- ✅ **Push Notifications** (하차 알림)
- ✅ **Background Modes** → Remote notifications, Background fetch

### 권한 확인 (Info.plist)
아래 키들이 Info.plist에 있는지 확인:
```
NSLocationWhenInUseUsageDescription  ← 위치 (날씨·탑승 추적)
NSPhotoLibraryUsageDescription       ← 사진 첨부
NSCameraUsageDescription             ← 카메라
```

---

## 🚀 6단계 — 앱스토어 배포

### TestFlight (내부 테스트)
1. Xcode → **Product → Archive**
2. Organizer → **Distribute App**
3. App Store Connect → TestFlight 업로드

### App Store 배포
1. [App Store Connect](https://appstoreconnect.apple.com) 접속
2. 앱 정보 입력:
   - 이름: 노르미
   - 부제: 어르신의 지하철 소풍을 돕는 동반자
   - 카테고리: 여행, 교통
3. 스크린샷 업로드 후 제출

---

## 🔑 Firestore 인덱스 설정

커뮤니티 피드 쿼리를 위해 아래 복합 인덱스가 필요합니다.
Firebase Console → Firestore → 인덱스 탭에서 추가:

| 컬렉션 | 필드 | 순서 |
|--------|------|------|
| `posts` | `authorUID` ASC, `createdAt` DESC | — |
| `posts` | `createdAt` DESC | — |

또는 앱 실행 시 콘솔에 출력되는 인덱스 생성 링크를 클릭하면 자동 생성됩니다.

---

## ⚠️ 주의사항

- **GoogleService-Info.plist**는 Git에 절대 커밋하지 마세요 (`.gitignore`에 추가)
- **API 키**도 Info.plist를 `.gitignore`에 추가하거나 Xcode Config 파일로 분리 관리 권장
- ODsay API는 HTTPS만 지원하므로 ATS 설정 확인 필요

---

## 📞 주요 기능 요약

| 탭 | 기능 |
|----|------|
| 🏠 홈 | 실시간 날씨, 나들이 지수, 주의사항, 소풍 추천지 |
| 🚶 소풍 | 4가지 카테고리 선택 → 역 선택 → 경로 연동 |
| 🚃 경로 | 역명 검색, 경로 탐색, 실시간 탑승 추적, 하차 알림 |
| 💬 커뮤니티 | 사진+글 게시, 좋아요, 댓글, 실시간 피드 |
| 👤 마이 | 내 기록 보기, 프로필 수정, 알림 설정, 로그아웃 |
