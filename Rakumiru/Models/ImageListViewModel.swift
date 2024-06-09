//
//  ImageListViewModel.swift
//  Rakumiru
//
//  Created by tetsu.kuribayashi on 2024/06/09.
//

/*
import Foundation
import SwiftUI

class ImageListViewModel: ObservableObject {
    @Published var selectedFacility: Facility?
    @Published var facilities: [Facility] = []
    @Published var users: [User] = []
    @Published var images: [String: [ImageData]] = [:]
    @Published var isLoading = false
    @Published var errorMessage: String?

    func fetchFacilities() {
        isLoading = true
        print("Fetching facilities...") // デバッグログ
        FirebaseManager.shared.fetchFacilities { result in
            DispatchQueue.main.async {
                self.isLoading = false
                switch result {
                case .success(let facilities):
                    print("Facilities fetched: \(facilities)") // デバッグログ
                    self.facilities = facilities
                    if let latestFacility = facilities.sorted(by: { $0.submittedAt > $1.submittedAt }).first {
                        self.selectedFacility = latestFacility
                        self.fetchUsers()
                    }
                case .failure(let error):
                    self.errorMessage = "Failed to load facilities: \(error.localizedDescription)"
                    print("Error fetching facilities: \(error.localizedDescription)") // デバッグログ
                }
            }
        }
    }

    
    func fetchUsers() {
        guard let facility = selectedFacility else {
            errorMessage = "Please select a facility."
            return
        }
        
        isLoading = true
        FirebaseManager.shared.fetchUsers(for: facility.id) { result in
            DispatchQueue.main.async {
                self.isLoading = false
                switch result {
                case .success(let users):
                    self.users = users
                    self.errorMessage = nil // エラーメッセージをクリア
                    self.fetchImages(for: Date())
                case .failure(let error):
                    self.errorMessage = "Failed to load users: \(error.localizedDescription)"
                }
            }
        }
    }
    
    func fetchImages(for date: Date) {
        guard !users.isEmpty else {
            errorMessage = "No users found."
            return
        }
        
        isLoading = true
        images = [:]
        
        let group = DispatchGroup()
        
        for user in users {
            group.enter()
            FirebaseManager.shared.fetchImages(for: user.id) { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let userImages):
                        self.images[user.id] = userImages
                    case .failure(let error):
                        self.errorMessage = "Failed to load images: \(error.localizedDescription)"
                    }
                    group.leave()
                }
            }
        }
        
        group.notify(queue: .main) {
            self.isLoading = false
        }
    }
}

*/
