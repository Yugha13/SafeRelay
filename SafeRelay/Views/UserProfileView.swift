//
// UserProfileView.swift
// SafeRelay
//

import SwiftUI

struct UserProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var manager = UserProfileManager.shared
    @State private var showAddContact = false
    @State private var newContactName = ""
    @State private var newContactRelation = ""
    @State private var newContactPhone = ""

    private let genderOptions = ["Male", "Female", "Non-binary", "Prefer not to say"]
    private let bloodGroups = ["A+", "A-", "B+", "B-", "AB+", "AB-", "O+", "O-", "Unknown"]

    var body: some View {
        NavigationStack {
            Form {
                // MARK: - Header card
                Section {
                    HStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(LinearGradient(
                                    colors: [.red, .orange],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing))
                                .frame(width: 70, height: 70)
                            Text(initials)
                                .font(.title)
                                .bold()
                                .foregroundColor(.white)
                        }
                        VStack(alignment: .leading, spacing: 4) {
                            Text(manager.profile.fullName.isEmpty ? "SafeRelay User" : manager.profile.fullName)
                                .font(.title3).bold()
                            if !manager.profile.bloodGroup.isEmpty {
                                Label(manager.profile.bloodGroup, systemImage: "drop.fill")
                                    .font(.subheadline)
                                    .foregroundColor(.red)
                            }
                            if manager.profile.isComplete {
                                Label("Profile complete", systemImage: "checkmark.seal.fill")
                                    .font(.caption)
                                    .foregroundColor(.green)
                            } else {
                                Label("Complete your profile", systemImage: "exclamationmark.circle")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                            }
                        }
                    }
                    .padding(.vertical, 6)
                }

                // MARK: - Personal Information
                Section {
                    profileRow(icon: "person.fill", label: "Full Name", value: $manager.profile.fullName, placeholder: "Your full name")
                    profileRow(icon: "calendar", label: "Age", value: $manager.profile.age, placeholder: "e.g. 28")
                    pickerRow(icon: "figure.stand", label: "Gender", selection: $manager.profile.gender, options: genderOptions)
                    profileRow(icon: "phone.fill", label: "Phone", value: $manager.profile.phone, placeholder: "+91 XXXXX XXXXX")
                    profileRow(icon: "house.fill", label: "Address", value: $manager.profile.address, placeholder: "Street / Locality")
                    profileRow(icon: "map.fill", label: "City", value: $manager.profile.city, placeholder: "City")
                    profileRow(icon: "map", label: "State", value: $manager.profile.state, placeholder: "State")
                    profileRow(icon: "number", label: "Pincode", value: $manager.profile.pincode, placeholder: "6-digit pincode")
                } header: {
                    sectionHeader("Personal Information", icon: "person.crop.circle")
                }

                // MARK: - Health Information
                Section {
                    pickerRow(icon: "drop.fill", label: "Blood Group", selection: $manager.profile.bloodGroup, options: bloodGroups)
                    profileRow(icon: "cross.case.fill", label: "Medical Conditions", value: $manager.profile.medicalConditions, placeholder: "Diabetes, Asthma…")
                    profileRow(icon: "pills.fill", label: "Medications", value: $manager.profile.medications, placeholder: "Metformin 500mg…")
                    profileRow(icon: "exclamationmark.triangle.fill", label: "Allergies", value: $manager.profile.allergies, placeholder: "Penicillin, Peanuts…")
                    profileRow(icon: "figure.roll", label: "Disabilities", value: $manager.profile.disabilities, placeholder: "If any…")
                    Toggle(isOn: $manager.profile.organDonor) {
                        Label("Organ Donor", systemImage: "heart.fill")
                    }
                    .tint(.red)
                    profileRow(icon: "stethoscope", label: "Doctor Name", value: $manager.profile.doctorName, placeholder: "Dr. Name")
                    profileRow(icon: "phone.circle.fill", label: "Doctor Phone", value: $manager.profile.doctorPhone, placeholder: "+91 XXXXX XXXXX")
                } header: {
                    sectionHeader("Health Information", icon: "heart.text.square")
                }

                // MARK: - Family / Emergency Contacts
                Section {
                    ForEach($manager.profile.emergencyContacts) { $contact in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Image(systemName: "person.2.fill").foregroundColor(.red)
                                Text(contact.name.isEmpty ? "Contact" : contact.name).bold()
                                Spacer()
                                Text(contact.relation).font(.caption).foregroundColor(.secondary)
                            }
                            HStack {
                                Image(systemName: "phone.fill").foregroundColor(.green).font(.caption)
                                Text(contact.phone).font(.subheadline).foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .onDelete { indices in
                        manager.profile.emergencyContacts.remove(atOffsets: indices)
                        manager.save()
                    }

                    Button {
                        showAddContact = true
                    } label: {
                        Label("Add Emergency Contact", systemImage: "plus.circle.fill")
                            .foregroundColor(.red)
                    }
                } header: {
                    sectionHeader("Emergency Contacts", icon: "figure.2.and.child.holdinghands")
                }
            }
            .navigationTitle("My Profile")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.large)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        manager.save()
                        dismiss()
                    }
                    .bold()
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(isPresented: $showAddContact) {
                addContactSheet
            }
        }
    }

    // MARK: - Add Contact Sheet
    private var addContactSheet: some View {
        NavigationStack {
            Form {
                Section("Contact Details") {
                    HStack {
                        Image(systemName: "person").foregroundColor(.secondary)
                        TextField("Full Name", text: $newContactName)
                    }
                    HStack {
                        Image(systemName: "person.2").foregroundColor(.secondary)
                        TextField("Relation (Mother, Father…)", text: $newContactRelation)
                    }
                    HStack {
                        Image(systemName: "phone").foregroundColor(.secondary)
                        TextField("Phone Number", text: $newContactPhone)
                            #if os(iOS)
                            .keyboardType(.phonePad)
                            #endif
                    }
                }
            }
            .navigationTitle("New Contact")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        guard !newContactName.isEmpty else { return }
                        manager.profile.emergencyContacts.append(
                            EmergencyContact(name: newContactName, relation: newContactRelation, phone: newContactPhone)
                        )
                        manager.save()
                        newContactName = ""
                        newContactRelation = ""
                        newContactPhone = ""
                        showAddContact = false
                    }
                    .bold()
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showAddContact = false }
                }
            }
        }
    }

    // MARK: - Helpers
    private var initials: String {
        let words = manager.profile.fullName.split(separator: " ")
        let letters = words.prefix(2).compactMap { $0.first }
        return letters.isEmpty ? "?" : letters.map(String.init).joined()
    }

    @ViewBuilder
    private func profileRow(icon: String, label: String, value: Binding<String>, placeholder: String) -> some View {
        HStack(alignment: .center, spacing: 10) {
            Image(systemName: icon)
                .foregroundColor(.red)
                .frame(width: 22)
            VStack(alignment: .leading, spacing: 2) {
                Text(label).font(.caption).foregroundColor(.secondary)
                TextField(placeholder, text: value)
                    .font(.body)
            }
        }
        .padding(.vertical, 2)
    }

    @ViewBuilder
    private func pickerRow(icon: String, label: String, selection: Binding<String>, options: [String]) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon).foregroundColor(.red).frame(width: 22)
            Picker(label, selection: selection) {
                Text("Select").tag("")
                ForEach(options, id: \.self) { Text($0).tag($0) }
            }
        }
    }

    @ViewBuilder
    private func sectionHeader(_ title: String, icon: String) -> some View {
        Label(title, systemImage: icon)
            .font(.headline)
            .textCase(nil)
            .foregroundColor(.primary)
    }
}
