import Foundation

struct ImportCheckInsBody: Encodable {
    let checkIns: [BackendCheckIn]
}
