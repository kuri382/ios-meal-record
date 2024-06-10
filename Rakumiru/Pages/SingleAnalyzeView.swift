import SwiftUI
import PhotosUI

struct SingleAnalyzeView: View {
    @State private var selectedImage: UIImage?
    @State private var isImagePickerPresented = false
    @State private var isLoading = false
    @State private var responseText: String?
    @State private var meals: [Meal] = []
    
    @State private var magnification: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero

    
    var body: some View {
        VStack {
            Spacer()
            
            if let image = selectedImage {
                GeometryReader { geometry in
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(width: geometry.size.width * 0.8, height: geometry.size.width * 0.8)
                        .scaleEffect(magnification)
                        .offset(x: offset.width, y: offset.height)
                        .gesture(
                            MagnificationGesture()
                                .onChanged { value in
                                    magnification = value
                                }
                                .simultaneously(with: DragGesture()
                                    .onChanged { value in
                                        offset = value.translation
                                    }
                                    .onEnded { value in
                                        lastOffset.width += value.translation.width
                                        lastOffset.height += value.translation.height
                                        offset = lastOffset
                                    }
                                )
                        )
                        .frame(width: geometry.size.width, height: geometry.size.height * 0.8, alignment: .center) // 中央寄せに調整
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .frame(width: 400)
            }
            
            if selectedImage == nil {
                Button(action: {
                    isImagePickerPresented = true
                }) {
                    HStack {
                        Image(systemName: "folder")
                            .font(.title2)
                        Text("写真を選択する")
                            .font(.title2)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color(.secondarySystemBackground))
                    .foregroundColor(Color(hex: "262260"))
                    .cornerRadius(10)
                    .shadow(color: Color(.systemGray4), radius: 5, x: 0, y: 2)
                }
                .padding()
                .disabled(isLoading)
            }
            
            if selectedImage != nil && meals.isEmpty {
                Button(action: {
                    uploadImage()
                }) {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                            .padding()
                    } else {
                        HStack {
                            Image(systemName: "fork.knife")
                                .font(.title2)
                            Text("食事を分析する")
                                .font(.title2)
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color(.secondarySystemBackground))
                        .foregroundColor(Color(hex: "262260"))
                        .cornerRadius(10)
                        .shadow(color: Color(.systemGray4), radius: 5, x: 0, y: 2)
                    }
                }
                .padding()
                .disabled(isLoading)
            }
            
            if meals.isEmpty {
                Text("")
            } else {
                List(meals) { meal in
                    VStack(alignment: .leading) {
                        Text(meal.name)
                            .font(.headline)
                        Text("残量: \(Int(meal.remaining * 100))%")
                        Text("栄養素: \(meal.nutrients)")
                        Text("重量: \(meal.weight)")
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
                        .frame(maxWidth: .infinity, maxHeight: 600) // 表示範囲を指定
                }
                .frame(maxWidth: .infinity, maxHeight: 600) // スクロールビューのサイズを指定
                .padding()
            }
            
            Spacer()
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
