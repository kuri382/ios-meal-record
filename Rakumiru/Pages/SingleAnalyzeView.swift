import SwiftUI
import PhotosUI

struct SingleAnalyzeView: View {
    @State private var selectedImage: UIImage?
    @State private var isImagePickerPresented = false
    @State private var isLoading = false
    @State private var responseText: String?
    @State private var meals: [Meal] = []
    
    var body: some View {
        VStack {
            if let image = selectedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200, height: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            
            if selectedImage == nil {
                Button(action: {
                    isImagePickerPresented = true
                }) {
                    Text("画像を選択")
                        .font(.title)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding()
                .disabled(isLoading)
            }
            
            if selectedImage != nil {
                Button(action: {
                    uploadImage()
                }) {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                            .padding()
                    } else {
                        Text("画像を送る")
                            .font(.title)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                }
                .padding()
                .disabled(isLoading)
            }
            if meals.isEmpty {
                Text("No meals data")
            } else {
                List(meals) { meal in
                    VStack(alignment: .leading) {
                        Text(meal.name)
                            .font(.headline)
                        Text("残量: \(Int(meal.remaining * 100))%")
                        Text("栄養素: \(meal.nutrients)")
                        Text("重量: \(meal.weight)")
                        //Text("ラベル: \(meal.label)")
                        Text("ラベル: \(meal.label == "staple" ? "主菜" : (meal.label == "side" ? "副菜" : meal.label))")

                    }
                }
            }
            
            if let responseText = responseText {
                ScrollView {
                    Text(responseText)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                        .frame(maxWidth: .infinity, maxHeight: 500) // 表示範囲を指定
                }
                .frame(maxWidth: .infinity, maxHeight: 500) // スクロールビューのサイズを指定
                .padding()
            }
        }
        .padding()
        .sheet(isPresented: $isImagePickerPresented) {
            ImagePicker(image: $selectedImage)
        }
    }
    
    
    func uploadImage() {
        guard let selectedImage = selectedImage else {
            print("Failed to load image")
            return
        }
        
        guard let processedImage = processImage(selectedImage: selectedImage) else {
            print("Image processing failed")
            return
        }
        
        print("Image processed successfully")
        
        isLoading = true
        responseText = nil
        
        FirebaseManager.shared.uploadImage(processedImage) { result in
            DispatchQueue.main.async {
                self.isLoading = false
                switch result {
                case .success(let url):
                    self.sendImageToGPT4(imageURL: url)
                case .failure(let error):
                    let errorMessage = "Error uploading image: \(error.localizedDescription)"
                    print(errorMessage)
                    self.responseText = errorMessage
                }
            }
        }
    }
    func sendImageToGPT4(imageURL: URL) {
        isLoading = true
        
        GPT4Service.shared.sendImageToGPT4(imageURL: imageURL) { gptResult in
            DispatchQueue.main.async {
                self.isLoading = false
                switch gptResult {
                case .success(let responseString):
                    //print("Response String: \(responseString)")
                    if let data = responseString.data(using: .utf8) {
                        do {
                            let gptResponse = try JSONDecoder().decode(GPT4oResponse.self, from: data)
                            let content = gptResponse.choices.first?.message.content ?? "No content"
                            
                            // Extract the JSON part from the content
                            if let jsonStartIndex = content.range(of: "```json\n")?.upperBound,
                               let jsonEndIndex = content.range(of: "\n```", range: jsonStartIndex..<content.endIndex)?.lowerBound {
                                let jsonString = String(content[jsonStartIndex..<jsonEndIndex])
                                if let jsonData = jsonString.data(using: .utf8) {
                                    let mealsData = try JSONDecoder().decode(MealsData.self, from: jsonData)
                                    self.meals = mealsData.meals
                                }
                            }
                        } catch {
                            print("Decoding error: \(error)")
                            self.responseText = "Failed to parse response"
                        }
                    } else {
                        self.responseText = "Failed to convert response string to data"
                    }
                case .failure(let error):
                    let errorMessage = "Error sending image to GPT-4: \(error.localizedDescription)"
                    print(errorMessage)
                    self.responseText = errorMessage
                }
            }
        }
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        var parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true, completion: nil)
            
            guard let provider = results.first?.itemProvider else { return }
            
            if provider.canLoadObject(ofClass: UIImage.self) {
                provider.loadObject(ofClass: UIImage.self) { image, _ in
                    DispatchQueue.main.async {
                        self.parent.image = image as? UIImage
                    }
                }
            }
        }
    }
}


#Preview {
    SingleAnalyzeView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
