import Foundation

extension Bundle {
    func decodeJSON<T: Decodable>(_ type: T.Type, from resource: String, withExtension ext: String = "json") -> T? {
        guard let url = url(forResource: resource, withExtension: ext),
              let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode(T.self, from: data)
        else { return nil }
        return decoded
    }
}
