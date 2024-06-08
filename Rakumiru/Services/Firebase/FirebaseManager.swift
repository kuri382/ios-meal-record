import FirebaseCore
import FirebaseDatabase
import FirebaseStorage
import UIKit

class FirebaseManager {
    static let shared = FirebaseManager()
    
    private init() {
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }
        db = Database.database(url: "https://tabemiru-dev-default-rtdb.asia-southeast1.firebasedatabase.app").reference()
    }
    
    let storage = Storage.storage()
    var db = Database.database().reference()
    
    func createFacility(facilityName: String, completion: @escaping (Result<String, Error>) -> Void) {
        let facilityId = db.child("facilities").childByAutoId().key ?? UUID().uuidString
        let facilityData: [String: Any] = [
            "facility_name": facilityName,
            "submitted_at": ServerValue.timestamp()
        ]
        db.child("facilities").child(facilityId).setValue(facilityData) { error, _ in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(facilityId))
            }
        }
    }
    
    func createUser(userName: String, userNumber: String, facilityId: String, completion: @escaping (Result<String, Error>) -> Void) {
        let userId = db.child("users").childByAutoId().key ?? UUID().uuidString
        let userData: [String: Any] = [
            "user_name": userName,
            "user_number": userNumber,
            "facility_id": facilityId,
            "submitted_at": ServerValue.timestamp()
        ]
        db.child("users").child(userId).setValue(userData) { error, _ in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(userId))
            }
        }
    }
    
    func uploadImage(_ image: UIImage, completion: @escaping (Result<URL, Error>) -> Void) {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            completion(.failure(NSError(domain: "Invalid image data", code: -1, userInfo: nil)))
            return
        }
        
        let storageRef = storage.reference().child("images/\(UUID().uuidString).jpg")
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
    
    func saveImage(userId: String, imageUrl: URL, completion: @escaping (Result<Void, Error>) -> Void) {
        let imageId = db.child("users").child(userId).child("images").childByAutoId().key ?? UUID().uuidString
        let imageData: [String: Any] = [
            "image_url": imageUrl.absoluteString,
            "submitted_at": ServerValue.timestamp()
        ]
        db.child("users").child(userId).child("images").child(imageId).setValue(imageData) { error, _ in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
    
    func fetchFacilities(completion: @escaping (Result<[Facility], Error>) -> Void) {
        db.child("facilities").observeSingleEvent(of: .value) { snapshot in
            var facilities: [Facility] = []
            for child in snapshot.children {
                if let childSnapshot = child as? DataSnapshot,
                   let facilityData = childSnapshot.value as? [String: Any],
                   let facilityName = facilityData["facility_name"] as? String,
                   let submittedAt = facilityData["submitted_at"] as? NSNumber {
                    let facility = Facility(id: childSnapshot.key, facilityName: facilityName, submittedAt: submittedAt.doubleValue)
                    facilities.append(facility)
                }
            }
            completion(.success(facilities))
        } withCancel: { error in
            completion(.failure(error))
        }
    }
    func fetchImages(for userId: String, completion: @escaping (Result<[ImageData], Error>) -> Void) {
        db.child("users").child(userId).child("images").observeSingleEvent(of: .value) { snapshot in
            var images: [ImageData] = []
            for child in snapshot.children {
                if let childSnapshot = child as? DataSnapshot,
                   let imageData = childSnapshot.value as? [String: Any],
                   let imageUrl = imageData["image_url"] as? String,
                   let submittedAt = imageData["submitted_at"] as? Double {
                    let image = ImageData(id: childSnapshot.key, imageUrl: imageUrl, submittedAt: submittedAt)
                    images.append(image)
                }
            }
            completion(.success(images))
        } withCancel: { error in
            completion(.failure(error))
        }
    }
    
    func fetchImageURL(imagePath: String, completion: @escaping (Result<URL, Error>) -> Void) {
        let storageRef = storage.reference(withPath: imagePath)
        storageRef.downloadURL { url, error in
            if let error = error {
                completion(.failure(error))
            } else if let url = url {
                completion(.success(url))
            }
        }
    }
}
