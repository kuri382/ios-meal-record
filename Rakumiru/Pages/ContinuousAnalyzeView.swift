import SwiftUI
import Combine

struct ContinuousAnalyzeView: View {
    @State private var isCapturing = false
    @State private var capturedImages: [UIImage] = []
    @State private var isLoading = false
    @State private var responseText: String?
    @State private var userId: String?

    var body: some View {
        VStack {
            if isCapturing {
                CameraView(didCapturePhoto: { image in
                    self.processCapturedImage(image)
                })
                .overlay(
                    Rectangle()
                        .stroke(Color.red, lineWidth: 2)
                        .frame(width: 300, height: 300)
                )
                
                Button("Stop Capturing") {
                    stopCapturing()
                }
                .padding()
                .background(Color.red)
                .foregroundColor(.white)
                .cornerRadius(10)
            } else {
                Button("Start Capturing") {
                    startCapturing()
                }
                .padding()
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            
            if isLoading {
                ProgressView("Uploading Images...")
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("QRCodeDetected"))) { notification in
            if let userInfo = notification.userInfo, let qrCodeString = userInfo["qrCodeString"] as? String {
                if let userQRCode = QRCodeScanner.decodeQRCode(from: qrCodeString) {
                    self.userId = userQRCode.user_id
                    print("Received userId: \(userQRCode.user_id)")
                }
            }
        }
    }
    
    func startCapturing() {
        isCapturing = true
        capturedImages.removeAll()
    }
    
    func stopCapturing() {
        isCapturing = false
        uploadImages()
    }
    
    func processCapturedImage(_ image: UIImage) {
        guard capturedImages.count < 40 else { return }
        
        if let resizedImage = image.resize(toWidth: 1200), let compressedImage = resizedImage.jpegData(compressionQuality: 0.7) {
            if let finalImage = UIImage(data: compressedImage) {
                capturedImages.append(finalImage)
            }
        }
    }
    
    func uploadImages() {
        guard let userId = userId else {
            print("No userId available")
            return
        }
        
        isLoading = true
        let group = DispatchGroup()
        
        for image in capturedImages {
            group.enter()
            FirebaseManager.shared.uploadImage(image) { result in
                switch result {
                case .success(let url):
                    FirebaseManager.shared.saveImage(userId: userId, imageUrl: url) { result in
                        switch result {
                        case .success:
                            print("Image saved successfully")
                        case .failure(let error):
                            print("Failed to save image: \(error)")
                        }
                    }
                case .failure(let error):
                    print("Failed to upload image: \(error)")
                }
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            isLoading = false
            print("All images uploaded")
        }
    }
}

struct ContinuousAnalyzeView_Previews: PreviewProvider {
    static var previews: some View {
        ContinuousAnalyzeView()
    }
}
