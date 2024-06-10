import SwiftUI

struct FacilityRegistrationView: View {
    @State private var facilityName = ""
    @State private var isLoading = false
    @State private var successMessage: String?
    @State private var errorMessage: String?
    
    var body: some View {
        VStack(spacing: 20) {
        
                TextField("施設名を入力する", text: $facilityName)
                .font(.title2)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)
                    .frame(height: 50)
            
            Button(action: registerFacility) {
                HStack {
                    Image(systemName: "plus.circle")
                        .font(.title2)
                    Text("施設を登録する")
                        .font(.title2)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color(.secondarySystemBackground))
                .foregroundColor(Color(hex: "262260"))
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
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .padding()
    }
    
    func registerFacility() {
        successMessage = nil
        errorMessage = nil
        isLoading = true
        FirebaseManager.shared.createFacility(facilityName: facilityName) { result in
            isLoading = false
            switch result {
            case .success(_):
                successMessage = "\(facilityName)を登録しました"
                facilityName = "" // Clear the text field on success
            case .failure(let error):
                errorMessage = "施設登録に失敗しました: \(error.localizedDescription)"
            }
        }
    }
}

/*
 struct FacilityRegistrationView_Previews: PreviewProvider {
 static var previews: some View {
 FacilityRegistrationView()
 }
 }
 */
