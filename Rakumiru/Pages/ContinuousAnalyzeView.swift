import SwiftUI
import Combine
import AVFoundation

struct ContinuousAnalyzeView: View {
    @State private var isCapturing = false
    @State private var capturedImages: [UIImage] = []
    @State private var isLoading = false
    @State private var responseText: String?
    @State private var currentUserId: String?
    @State private var player: AVAudioPlayer?
    
    var body: some View {
        VStack {
            if isCapturing {
                CameraView(didCapturePhoto: { image in
                    self.processCapturedImage(image)
                })
                .overlay(
                    Rectangle()
                        .stroke(Color.green, lineWidth: 2)
                        .frame(width: 200, height: 300)
                )
                
                Button(action: {
                    stopCapturing()
                }) {
                    HStack {
                        Image(systemName: "folder")
                            .font(.title2)
                        Text("読み取り終了")
                            .font(.title2)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color(.secondarySystemBackground))
                    .foregroundColor(Color(hex: "262260"))
                    .cornerRadius(10)
                    .shadow(color: Color(.systemGray4), radius: 5, x: 0, y: 2)
                    .frame(maxWidth: UIScreen.main.bounds.width * 0.8) // 親ビューの幅の80%に制限
                }
            } else {
                Button(action: {
                    startCapturing()
                }) {
                    HStack {
                        Image(systemName: "fork.knife")
                            .font(.title2)
                        Text("読み取り開始")
                            .font(.title2)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color(.secondarySystemBackground))
                    .foregroundColor(Color(hex: "262260"))
                    .cornerRadius(10)
                    .shadow(color: Color(.systemGray4), radius: 5, x: 0, y: 2)
                    .frame(maxWidth: UIScreen.main.bounds.width * 0.8) // 親ビューの幅の80%に制限
                }
            }
            /*
             if isLoading {
             ProgressView("Uploading Images...")
             }
             */
        }
        .onAppear {
            startCapturing()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("QRCodeDetected"))) { notification in
            if let userInfo = notification.userInfo, let userId = userInfo["userId"] as? String {
                self.currentUserId = userId
                //print("Received userId: \(userId)")
                playSound()
                self.uploadImages(for: userId)
            }
        }
    }
    
    func startCapturing() {
        isCapturing = true
        capturedImages.removeAll()
    }
    
    func stopCapturing() {
        isCapturing = false
    }
    
    func processCapturedImage(_ image: UIImage) {
        guard capturedImages.count < 40 else { return }
        
        if let resizedImage = image.resize(toWidth: 1200), let compressedImage = resizedImage.jpegData(compressionQuality: 0.7) {
            if let finalImage = UIImage(data: compressedImage) {
                capturedImages.append(finalImage)
                // ユーザーIDに対して即座に画像を保存
                if let userId = currentUserId {
                    uploadImages(for: userId)
                }
            }
        }
    }
    
    func uploadImages(for userId: String) {
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
                            print("Image saved successfully for user \(userId)")
                            DispatchQueue.global(qos: .background).async {
                                self.sendImageToGPT4(imageURL: url, userId: userId)
                            }
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
            print("All images uploaded for user \(userId)")
            capturedImages.removeAll()
        }
    }
    
    func sendImageToGPT4(imageURL: URL, userId: String) {
        GPT4Service.shared.sendImageToGPT4(imageURL: imageURL) { gptResult in
            DispatchQueue.main.async {
                switch gptResult {
                case .success(let responseString):
                    if let data = responseString.data(using: .utf8) {
                        do {
                            let gptResponse = try JSONDecoder().decode(GPT4oResponse.self, from: data)
                            let content = gptResponse.choices.first?.message.content ?? "No content"
                            print("Response from GPT-4: \(content)")
                            
                            if let jsonStartIndex = content.range(of: "```json\n")?.upperBound,
                               let jsonEndIndex = content.range(of: "\n```", range: jsonStartIndex..<content.endIndex)?.lowerBound {
                                let jsonString = String(content[jsonStartIndex..<jsonEndIndex])
                                if let jsonData = jsonString.data(using: .utf8) {
                                    let mealsData = try JSONDecoder().decode(MealsData.self, from: jsonData)
                                    FirebaseManager.shared.saveMealDataWithRetry(userId: userId, imageUrl: imageURL, mealsData: mealsData) { result in
                                        switch result {
                                        case .success:
                                            print("Meal data saved successfully for user \(userId)")
                                        case .failure(let error):
                                            print("Failed to save meal data after retries: \(error)")
                                        }
                                    }
                                }
                            }
                        } catch {
                            print("Decoding error: \(error)")
                        }
                    } else {
                        print("Failed to convert response string to data")
                    }
                case .failure(let error):
                    let errorMessage = "Error sending image to GPT-4: \(error.localizedDescription)"
                    print(errorMessage)
                }
            }
        }
    }

    
    func playSound() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to set audio session category: \(error)")
        }
        
        guard let url = Bundle.main.url(forResource: "beep", withExtension: "mp3") else { return }
        do {
            self.player = try AVAudioPlayer(contentsOf: url)
            self.player?.play()
        } catch {
            print("Error playing sound: \(error)")
        }
    }
}


struct ContinuousAnalyzeView_Previews: PreviewProvider {
    static var previews: some View {
        ContinuousAnalyzeView()
    }
}
