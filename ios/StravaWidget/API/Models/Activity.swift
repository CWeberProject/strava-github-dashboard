import Foundation

struct StravaActivity: Codable {
    let id: Int64
    let name: String
    let type: String
    let sportType: String?
    let startDate: String
    let startDateLocal: String
    let distance: Double
    let movingTime: Int
    let elapsedTime: Int
    let totalElevationGain: Double?

    enum CodingKeys: String, CodingKey {
        case id, name, type, distance
        case sportType = "sport_type"
        case startDate = "start_date"
        case startDateLocal = "start_date_local"
        case movingTime = "moving_time"
        case elapsedTime = "elapsed_time"
        case totalElevationGain = "total_elevation_gain"
    }
}
