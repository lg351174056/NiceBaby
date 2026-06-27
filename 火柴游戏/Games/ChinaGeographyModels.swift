import Foundation

struct GeoFeatureCollection: Decodable {
    let features: [GeoFeature]
}

struct GeoFeature: Decodable, Identifiable {
    var id: String { properties.id ?? properties.name }
    let properties: GeoProperties
    let geometry: GeoGeometry
}

struct GeoProperties: Decodable {
    let id: String?
    let name: String
    let cp: [Double]?
    let childNum: Int?
}

struct GeoPolygon: Decodable {
    let rings: [[[Double]]]
}

struct GeoGeometry: Decodable {
    let type: String
    let polygons: [GeoPolygon]

    enum CodingKeys: String, CodingKey {
        case type, coordinates
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        type = try container.decode(String.self, forKey: .type)

        if type == "Polygon" {
            let coords = try container.decode([[[Double]]].self, forKey: .coordinates)
            self.polygons = [GeoPolygon(rings: coords)]
        } else if type == "MultiPolygon" {
            let coords = try container.decode([[[[Double]]]].self, forKey: .coordinates)
            self.polygons = coords.map { GeoPolygon(rings: $0) }
        } else {
            self.polygons = []
        }
    }
}
