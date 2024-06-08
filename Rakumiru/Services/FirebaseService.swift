import FirebaseStorage

class FirebaseManager {
    static let shared = FirebaseManager()

    private init() {
        FirebaseApp.configure()
    }

    func uploadImage(_ image: UIImage, completion: @escaping (Result<URL, Error>) -> Void) {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            completion(.failure(NSError(domain: "Invalid image data", code: -1, userInfo: nil)))
            return
        }

        let storageRef = Storage.storage().reference().child("images/\(UUID().uuidString).jpg")
        storageRef.putData(imageData, metadata: nil) { metadata, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            storageRef.downloadURL { url, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }

                guard let downloadURL = url else {
                    completion(.failure(NSError(domain: "Download URL is nil", code: -1, userInfo: nil)))
                    return
                }

                completion(.success(downloadURL))
            }
        }
    }
}
