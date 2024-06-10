import Foundation
import SwiftUI

struct UserDetailView: View {
    var userId: String
    var userName: String
    @State private var userImages: [ImageData] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        VStack(alignment: .leading) {
            if isLoading {
                ProgressView("Loading data...")
                    .padding()
            } else if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .padding()
            } else {
                List(userImages.sorted(by: { $0.submittedAt > $1.submittedAt })) { image in
                    ImageView(image: image)
                }
            }
        }
        .navigationTitle("\(userName)様の詳細情報")
        .padding()
        .onAppear {
            fetchImages()
        }
    }
    
    private func fetchImages() {
        print("Fetching images for userId: \(userId)")
        isLoading = true
        errorMessage = nil
        
        FirebaseManager.shared.fetchImages(for: userId) { result in
            DispatchQueue.main.async {
                self.isLoading = false
                switch result {
                case .success(let images):
                    self.userImages = images
                case .failure(let error):
                    print("Failed to fetch images: \(error.localizedDescription)")
                    self.errorMessage = "Failed to load images: \(error.localizedDescription)"
                }
            }
        }
    }
}

#Preview {
    UserDetailView(userId:"-Nzv7hr_ygX1Bct7zmCx", userName: "サンプル太郎").environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
