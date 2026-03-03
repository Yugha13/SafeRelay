//
// UserProfile.swift
// SafeRelay
//

import Foundation

struct EmergencyContact: Codable, Identifiable {
    var id = UUID()
    var name: String = ""
    var relation: String = ""
    var phone: String = ""
}

struct UserProfile: Codable {
    // Personal
    var fullName: String = ""
    var age: String = ""
    var gender: String = ""
    var phone: String = ""
    var address: String = ""
    var city: String = ""
    var state: String = ""
    var pincode: String = ""

    // Health
    var bloodGroup: String = ""
    var allergies: String = ""
    var medications: String = ""
    var medicalConditions: String = ""
    var disabilities: String = ""
    var organDonor: Bool = false

    // Family / Emergency Contacts
    var emergencyContacts: [EmergencyContact] = []
    var doctorName: String = ""
    var doctorPhone: String = ""

    // Profile completion
    var isComplete: Bool {
        !fullName.isEmpty && !bloodGroup.isEmpty && !emergencyContacts.isEmpty
    }
}

@MainActor
final class UserProfileManager: ObservableObject {
    static let shared = UserProfileManager()

    private let saveKey = "saferelay.userProfile"

    @Published var profile: UserProfile = UserProfile()

    private init() {
        load()
    }

    func save() {
        if let data = try? JSONEncoder().encode(profile) {
            UserDefaults.standard.set(data, forKey: saveKey)
        }
    }

    private func load() {
        if let data = UserDefaults.standard.data(forKey: saveKey),
           let p = try? JSONDecoder().decode(UserProfile.self, from: data) {
            self.profile = p
        }
    }

    /// Display name for chat: uses fullName if set, otherwise returns the nickname string
    func displayName(fallback: String) -> String {
        profile.fullName.isEmpty ? fallback : profile.fullName
    }
}
