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
        let databaseUrl = Config.FirebaseDbUrl
        db = Database.database(url: databaseUrl).reference()
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
    
    func fetchUsers(for facilityId: String, completion: @escaping (Result<[User], Error>) -> Void) {
        db.child("users").queryOrdered(byChild: "facility_id").queryEqual(toValue: facilityId).observeSingleEvent(of: .value) { snapshot in
            var users: [User] = []
            for child in snapshot.children {
                if let childSnapshot = child as? DataSnapshot,
                   let userData = childSnapshot.value as? [String: Any],
                   let userName = userData["user_name"] as? String,
                   let userNumber = userData["user_number"] as? String,
                   let facilityId = userData["facility_id"] as? String,
                   let submittedAt = userData["submitted_at"] as? Double {
                    let user = User(id: childSnapshot.key, userName: userName, userNumber: userNumber, submittedAt: submittedAt, facilityId: facilityId)
                    users.append(user)
                }
            }
            print("Fetched users: \(users)") // デバッグログ
            completion(.success(users))
        } withCancel: { error in
            print("Error fetching users: \(error.localizedDescription)") // デバッグログ
            completion(.failure(error))
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
            print("Snapshot received: \(snapshot)") // デバッグログ
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
            print("Facilities parsed: \(facilities)") // デバッグログ
            completion(.success(facilities))
        } withCancel: { error in
            print("Error receiving snapshot: \(error.localizedDescription)") // デバッグログ
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
                    
                    var meals: [Meal]? = nil
                    if let mealsData = imageData["meals"] as? [[String: Any]] {
                        meals = mealsData.compactMap { dict -> Meal? in
                            guard let label = dict["label"] as? String,
                                  let name = dict["name"] as? String,
                                  let nutrients = dict["nutrients"] as? String,
                                  let remaining = dict["remaining"] as? Double,
                                  let weight = dict["weight"] as? Int else {
                                return nil
                            }
                            return Meal(name: name, nutrients: nutrients, weight: Int64(weight), label: label, remaining: remaining)
                        }
                    }
                    
                    let image = ImageData(id: childSnapshot.key, imageUrl: imageUrl, submittedAt: submittedAt, meals: meals)
                    images.append(image)
                }
            }
            print("Fetched images: \(images)") // デバッグログ
            completion(.success(images))
        } withCancel: { error in
            print("Error fetching images: \(error.localizedDescription)") // デバッグログ
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
    
    func saveMealData(userId: String, imageUrl: URL, mealsData: MealsData, completion: @escaping (Result<Void, Error>) -> Void) {
        let imageRef = db.child("users").child(userId).child("images").queryOrdered(byChild: "image_url").queryEqual(toValue: imageUrl.absoluteString)
        imageRef.observeSingleEvent(of: .value) { snapshot in
            guard let imageSnapshot = snapshot.children.allObjects.first as? DataSnapshot else {
                completion(.failure(NSError(domain: "Image not found", code: -1, userInfo: nil)))
                return
            }
            
            let mealsRef = imageSnapshot.ref.child("meals")
            let mealsArray = mealsData.meals.map { try! JSONSerialization.jsonObject(with: JSONEncoder().encode($0)) as! [String: Any] }
            mealsRef.setValue(mealsArray) { error, _ in
                if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.success(()))
                }
            }
        }
    }
    
}
