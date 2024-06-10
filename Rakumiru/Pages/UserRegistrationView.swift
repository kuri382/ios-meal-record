import SwiftUI

struct UserRegistrationView: View {
    @State private var userName = ""
    @State private var selectedFacility: Facility?
    @State private var facilities: [Facility] = []
    @State private var isLoading = false
    @State private var successMessage: String?
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 20) {
            if facilities.isEmpty {
                ProgressView("施設読み込み中...")
                    .onAppear(perform: fetchFacilities)
            } else {
                Picker("施設を選択してください", selection: $selectedFacility) {
                    ForEach(facilities) { facility in
                        Text(facility.facilityName).tag(facility as Facility?)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .padding()

                TextField("利用者様氏名を入力してください", text: $userName)
                    .font(.title2)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                    .frame(height: 50)

                Button(action: registerUser) {
                    HStack {
                        Image(systemName: "person.badge.plus")
                            .font(.title2)
                        Text("登録する")
                            .font(.title2)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .shadow(color: Color(.systemGray4), radius: 5, x: 0, y: 2)
                }
                .disabled(isLoading)
                .padding(.horizontal)

                if let successMessage = successMessage {
                    Text(successMessage)
                        .foregroundColor(.green)
                        .padding(.horizontal)
                }

                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding(.horizontal)
                }

                if isLoading {
                    ProgressView("登録中...")
                        .padding(.horizontal)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
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

        FirebaseManager.shared.db.child("users").child(facility.id).observeSingleEvent(of: .value) { snapshot in
            let userCount = snapshot.childrenCount
            let userNumber = String(userCount + 1)

            FirebaseManager.shared.createUser(userName: userName, userNumber: userNumber, facilityId: facility.id) { result in
                isLoading = false
                switch result {
                case .success(_):
                    successMessage = "\(userName)を登録しました"
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

/*
 struct UserRegistrationView_Previews: PreviewProvider {
 static var previews: some View {
 UserRegistrationView()
 }
 }
 */
