// ============================================================
//  RouteModels.swift + SubwayService.swift
//  ODsay 공공 대중교통 API 기반
//  API 키: https://lab.odsay.com 에서 발급
//  Info.plist 에 ODSAY_API_KEY 키로 저장
// ============================================================

import Foundation
import CoreLocation

// MARK: - Models

struct SubwayRoute: Identifiable {
    let id = UUID()
    let totalTime: Int
    let totalFare: Int
    let totalWalk: Int
    let segments: [RouteSegment]
    var allStations: [StationStop] { segments.filter { $0.type == .subway }.flatMap { $0.stops } }
    var timeText: String { "\(totalTime)분" }
    var fareText: String { "\(totalFare)원" }
}

struct RouteSegment: Identifiable {
    let id = UUID()
    let type: SegType
    let lineName: String
    let lineCode: Int
    let startName: String
    let endName: String
    let stops: [StationStop]
    let sectionMin: Int
    let walkM: Int
    var lineColor: String { SubwayLineColors.hex(lineCode) }
}

enum SegType { case subway, walk }

struct StationStop: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let lat: Double
    let lon: Double
    var isCurrent: Bool = false
    var coordinate: CLLocationCoordinate2D { .init(latitude: lat, longitude: lon) }

    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    static func == (l: Self, r: Self) -> Bool { l.id == r.id }
}

struct SubwayLineColors {
    static func hex(_ code: Int) -> String {
        switch code {
        case 1:   return "#0052A4"
        case 2:   return "#00A84D"
        case 3:   return "#EF7C1C"
        case 4:   return "#00A5DE"
        case 5:   return "#996CAC"
        case 6:   return "#CD7C2F"
        case 7:   return "#747F00"
        case 8:   return "#E6186C"
        case 9:   return "#BDB092"
        case 100: return "#FF0000"
        case 104: return "#77C4A3"
        default:  return "#888888"
        }
    }
}

// MARK: - ODsay Response DTOs

struct ODsayResponse: Codable { let result: ODsayResult }
struct ODsayResult: Codable { let path: [ODsayPath] }
struct ODsayPath: Codable {
    let info: ODsayInfo
    let subPath: [ODsaySubPath]
}
struct ODsayInfo: Codable {
    let totalTime: Int
    let payment: Int
    let totalWalk: Int
    let totalStationCount: Int
}
struct ODsaySubPath: Codable {
    let trafficType: Int
    let sectionTime: Int
    let stationCount: Int?
    let distance: Int?
    let startName: String?
    let endName: String?
    let lane: [ODsayLane]?
    let passStopList: ODsayStopList?
}
struct ODsayLane: Codable { let name: String?; let subwayCode: Int? }
struct ODsayStopList: Codable { let stations: [ODsayStation] }
struct ODsayStation: Codable {
    let stationName: String
    let x: String
    let y: String
}

// MARK: - SubwayService

final class SubwayService {
    static let shared = SubwayService()
    private init() {}

    private var apiKey: String {
        (Bundle.main.object(forInfoDictionaryKey: "ODSAY_API_KEY") as? String) ?? "YOUR_ODSAY_API_KEY"
    }
    private let base = "https://api.odsay.com/v1/api"

    // 역명으로 좌표 검색
    func stationSearch(name: String) async throws -> [(String, CLLocationCoordinate2D)] {
        var c = URLComponents(string: "\(base)/searchStation")!
        c.queryItems = [.init(name:"stationName",value:name),
                        .init(name:"stationClass",value:"2"),
                        .init(name:"apiKey",value:apiKey)]
        let (d,_) = try await URLSession.shared.data(from: c.url!)
        guard let json = try? JSONSerialization.jsonObject(with: d) as? [String:Any],
              let result = json["result"] as? [String:Any],
              let stations = result["station"] as? [[String:Any]] else { return [] }
        return stations.compactMap {
            guard let n = $0["stationName"] as? String,
                  let x = Double($0["x"] as? String ?? ""),
                  let y = Double($0["y"] as? String ?? "") else { return nil }
            return (n, CLLocationCoordinate2D(latitude: y, longitude: x))
        }
    }

    // 경로 탐색
    func searchRoute(sx: Double, sy: Double, ex: Double, ey: Double) async throws -> [SubwayRoute] {
        var c = URLComponents(string: "\(base)/searchPubTransPathT")!
        c.queryItems = [.init(name:"SX",value:"\(sx)"),
                        .init(name:"SY",value:"\(sy)"),
                        .init(name:"EX",value:"\(ex)"),
                        .init(name:"EY",value:"\(ey)"),
                        .init(name:"apiKey",value:apiKey)]
        let (d,_) = try await URLSession.shared.data(from: c.url!)
        let res = try JSONDecoder().decode(ODsayResponse.self, from: d)
        return res.result.path.map(parseRoute)
    }

    private func parseRoute(_ path: ODsayPath) -> SubwayRoute {
        var segments: [RouteSegment] = []
        for sub in path.subPath {
            if sub.trafficType == 1 {
                let lane = sub.lane?.first
                let code = lane?.subwayCode ?? 0
                let stops: [StationStop] = sub.passStopList?.stations.map {
                    StationStop(name: $0.stationName,
                                lat: Double($0.y) ?? 0,
                                lon: Double($0.x) ?? 0)
                } ?? []
                segments.append(RouteSegment(type: .subway,
                                             lineName: lane?.name ?? "지하철",
                                             lineCode: code,
                                             startName: sub.startName ?? "",
                                             endName:   sub.endName ?? "",
                                             stops: stops,
                                             sectionMin: sub.sectionTime,
                                             walkM: 0))
            } else if sub.trafficType == 3 {
                segments.append(RouteSegment(type: .walk,
                                             lineName: "도보",
                                             lineCode: 0,
                                             startName: "", endName: "",
                                             stops: [],
                                             sectionMin: sub.sectionTime,
                                             walkM: sub.distance ?? 0))
            }
        }
        return SubwayRoute(totalTime: path.info.totalTime,
                           totalFare: path.info.payment,
                           totalWalk: path.info.totalWalk,
                           segments: segments)
    }
}
