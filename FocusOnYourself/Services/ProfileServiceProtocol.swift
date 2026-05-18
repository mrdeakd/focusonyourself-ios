import Foundation

protocol ProfileServiceProtocol: AnyObject {
    var profile: UserProfile { get }

    func updateProfile(_ profile: UserProfile)
}
