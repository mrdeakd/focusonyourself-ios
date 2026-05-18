import Foundation

protocol ProfileRepositoryProtocol: AnyObject {
    func update(_ profile: UserProfile)
    func resetAll()
}
