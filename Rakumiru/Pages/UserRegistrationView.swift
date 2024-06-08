import SwiftUI

struct UserRegistrationView: View {
    @State private var userName = ""
    @State private var selectedFacility: Facility?
    @State private var facilities: [Facility] = []
    @State private var isLoading = false
    @State private var successMessage: String?
    @State private var errorMessage: String?

    var body: some View {
        VStack {
            if facilities.isEmpty {
                ProgressView("Loading facilities...")
                    .onAppear(perform: fetchFacilities)
            } else {
                Picker("Select Facility", selection: $selectedFacility) {
                    ForEach(facilities) { facility in
                        Text(facility.facilityName).tag(facility as Facility?)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .padding()

                TextField("User Name", text: $userName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()

                Button(action: registerUser) {
                    Text("Register User")
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding()

                if let successMessage = successMessage {
                    Text(successMessage)
                        .foregroundColor(.green)
                        .padding()
                }

                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding()
                }

                if isLoading {
                    ProgressView("Registering...")
                }
            }
        }
        .padding()
        .onAppear {
            fetchFacilities()
        }
    }

    func fetchFacilities() {
        isLoading = true
        FirebaseManager.shared.fetchFacilities { result in
            isLoading = false
            switch result {
            case .success(let facilities):
                self.facilities = facilities
                if !facilities.isEmpty {
                    self.selectedFacility = facilities.first
                }
            case .failure(let error):
                self.errorMessage = "Failed to load facilities: \(error.localizedDescription)"
            }
        }
    }

    func registerUser() {
        guard let facility = selectedFacility else {
            errorMessage = "Please select a facility."
            return
        }

        isLoading = true
        errorMessage = nil
        successMessage = nil

        // 自動でユーザー番号を設定（施設内のユーザー数 + 1）
        FirebaseManager.shared.db.child("users").child(facility.id).observeSingleEvent(of: .value) { snapshot in
            let userCount = snapshot.childrenCount
            let userNumber = String(userCount + 1)

            FirebaseManager.shared.createUser(userName: userName, userNumber: userNumber, facilityId: facility.id) { result in
                isLoading = false
                switch result {
                case .success(let userId):
                    successMessage = "User registered with ID: \(userId)"
                    userName = "" // Clear the text field on success
                case .failure(let error):
                    errorMessage = "Failed to register user: \(error.localizedDescription)"
                }
            }
        } withCancel: { error in
            isLoading = false
            errorMessage = "Failed to count users: \(error.localizedDescription)"
        }
    }
}
