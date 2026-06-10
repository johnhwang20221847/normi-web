// ============================================================
//  WeatherModels.swift
// ============================================================

import Foundation

// MARK: - OpenWeatherMap Response

struct WeatherResponse: Codable {
    let weather: [WeatherCondition]
    let main: MainWeather
    let wind: Wind
    let name: String
    let dt: TimeInterval
}
struct WeatherCondition: Codable {
    let id: Int; let main: String; let description: String; let icon: String
}
struct MainWeather: Codable {
    let temp, feelsLike, tempMin, tempMax: Double
    let humidity: Int
    enum CodingKeys: String, CodingKey {
        case temp, humidity
        case feelsLike = "feels_like"
        case tempMin   = "temp_min"
        case tempMax   = "temp_max"
    }
}
struct Wind: Codable { let speed: Double }

struct AirQualityResponse: Codable { let list: [AirQualityItem] }
struct AirQualityItem: Codable { let main: AQIMain; let components: AQIComponents }
struct AQIMain: Codable { let aqi: Int }
struct AQIComponents: Codable {
    let pm2_5: Double; let pm10: Double
    enum CodingKeys: String, CodingKey { case pm2_5 = "pm2_5"; case pm10 = "pm10" }
}

// MARK: - App Weather Model

struct WeatherInfo {
    let cityName: String
    let tempK: Double          // Kelvin
    let feelsLikeK: Double
    let tempMinK: Double
    let tempMaxK: Double
    let humidity: Int
    let description: String
    let iconCode: String
    let windSpeed: Double
    let aqi: Int
    let pm25: Double

    var tempC: Int     { Int(tempK - 273.15) }
    var maxC: Int      { Int(tempMaxK - 273.15) }
    var minC: Int      { Int(tempMinK - 273.15) }
    var feelsC: Int    { Int(feelsLikeK - 273.15) }
    var tempText: String { "\(tempC)°C" }
    var rangeText: String { "최고 \(maxC)° / 최저 \(minC)°" }

    // 나들이 지수
    var outingIndex: OutingIndex {
        let temp = tempC
        if temp < 0 || temp > 35 || aqi >= 4 || ["11d","11n"].contains(iconCode) {
            return .bad
        } else if temp < 8 || temp > 30 || aqi == 3 || ["09d","09n","10d","10n"].contains(iconCode) {
            return .fair
        } else {
            return .good
        }
    }

    var weatherEmoji: String {
        switch iconCode {
        case "01d": return "☀️"
        case "01n": return "🌙"
        case "02d","02n": return "⛅️"
        case "03d","03n","04d","04n": return "☁️"
        case "09d","09n": return "🌧️"
        case "10d": return "🌦️"
        case "10n": return "🌧️"
        case "11d","11n": return "⛈️"
        case "13d","13n": return "❄️"
        case "50d","50n": return "🌫️"
        default: return "🌤️"
        }
    }

    var aqiText: String {
        switch aqi {
        case 1: return "좋음"
        case 2: return "보통"
        case 3: return "나쁨"
        case 4: return "매우나쁨"
        default: return "위험"
        }
    }

    var tips: [WeatherTip] {
        var list: [WeatherTip] = []
        if tempC >= 33 {
            list.append(.init(icon:"🥵", title:"폭염 주의보",     detail:"물을 자주 마시고 그늘에서 쉬세요.", level:.warning))
        } else if tempC >= 28 {
            list.append(.init(icon:"☀️", title:"더운 날씨",       detail:"수분을 충분히 보충하세요.", level:.caution))
        }
        if tempC <= 0 {
            list.append(.init(icon:"🥶", title:"한파 주의보",     detail:"두꺼운 옷과 핫팩을 챙기세요.", level:.warning))
        } else if tempC <= 10 {
            list.append(.init(icon:"🧥", title:"쌀쌀한 날씨",    detail:"겉옷을 꼭 챙기세요.", level:.caution))
        }
        if ["09d","09n","10d","10n"].contains(iconCode) {
            list.append(.init(icon:"☂️", title:"비 예보",         detail:"우산을 꼭 챙기세요.", level:.caution))
        }
        if ["11d","11n"].contains(iconCode) {
            list.append(.init(icon:"⛈️", title:"뇌우 주의",      detail:"가급적 외출을 삼가세요.", level:.warning))
        }
        if ["13d","13n"].contains(iconCode) {
            list.append(.init(icon:"🧤", title:"눈 예보",         detail:"미끄럼에 조심하세요.", level:.caution))
        }
        if aqi >= 4 {
            list.append(.init(icon:"😷", title:"미세먼지 매우나쁨", detail:"마스크를 반드시 착용하세요.", level:.warning))
        } else if aqi == 3 {
            list.append(.init(icon:"🌫️", title:"미세먼지 나쁨",   detail:"마스크 착용을 권장합니다.", level:.caution))
        }
        if windSpeed >= 14 {
            list.append(.init(icon:"💨", title:"강풍 주의보",     detail:"낙하물을 조심하세요.", level:.caution))
        }
        return list.isEmpty
            ? [.init(icon:"😊", title:"쾌적한 날씨", detail:"오늘 소풍하기 좋은 날이에요!", level:.good)]
            : list
    }
}

enum OutingIndex {
    case good, fair, bad
    var text: String { switch self { case .good: "좋음"; case .fair: "보통"; case .bad: "나쁨" } }
    var color: String { switch self { case .good: "#4CAF82"; case .fair: "#F4A928"; case .bad: "#E85353" } }
    var emoji: String { switch self { case .good: "😊"; case .fair: "😐"; case .bad: "😟" } }
}

struct WeatherTip: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let detail: String
    let level: TipLevel
}
enum TipLevel {
    case good, caution, warning
    var color: String { switch self { case .good: "#4CAF82"; case .caution: "#F4A928"; case .warning: "#E85353" } }
}
