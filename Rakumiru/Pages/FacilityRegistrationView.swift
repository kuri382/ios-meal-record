import SwiftUI

struct FacilityRegistrationView: View {
    @State private var facilityName = ""
    @State private var isLoading = false
    @State private var successMessage: String?
    @State private var errorMessage: String?

    var body: some View {
        VStack {
            TextField("Facility Name", text: $facilityName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            
            Button(action: registerFacility) {
                Text("Register Facility")
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
        .padding()
    }
    
    func registerFacility() {
        successMessage = nil
        errorMessage = nil
        isLoading = true
        FirebaseManager.shared.createFacility(facilityName: facilityName) { result in
            isLoading = false
            switch result {
            case .success(let facilityId):
                successMessage = "Facility registered with ID: \(facilityId)"
                facilityName = "" // Clear the text field on success
            case .failure(let error):
                errorMessage = "Failed to register facility: \(error.localizedDescription)"
            }
        }
    }
}
