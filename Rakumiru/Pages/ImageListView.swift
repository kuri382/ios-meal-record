import SwiftUI
import FirebaseDatabaseInternal

struct ImageListView: View {
    @State private var selectedFacility: Facility?
    @State private var selectedDate: Date = Date()
    @State private var facilities: [Facility] = []
    @State private var users: [User] = []
    @State private var images: [String: [URL]] = [:]
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        VStack {
            if facilities.isEmpty {
                ProgressView("Loading facilities...")
                    .onAppear(perform: fetchFacilities)
            } else {
                Picker("Select Facility", selection: $selectedFacility) {
                    ForEach(facilities) { facility in
                        Text(facility.facilityName).tag(facility as Facility?)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .padding()
                .onChange(of: selectedFacility) { _ in
                    fetchUsers()
                }
                
                DatePicker("Select Date", selection: $selectedDate, displayedComponents: .date)
                    .padding()
                    .onChange(of: selectedDate) { _ in
                        fetchImages()
                    }

                if isLoading {
                    ProgressView("Loading data...")
                } else if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding()
                } else {
                    List(users) { user in
                        VStack(alignment: .leading) {
                            Text(user.userName)
                                .font(.headline)
                            if let userImages = images[user.id], !userImages.isEmpty {
                                ForEach(userImages, id: \.self) { imageUrl in
                                    HStack {
                                        AsyncImage(url: imageUrl) { phase in
                                            if let image = phase.image {
                                                image.resizable()
                                                    .scaledToFill()
                                                    .frame(width: 100, height: 100)
                                                    .clipped()
                                            } else if phase.error != nil {
                                                Color.red
                                                    .frame(width: 100, height: 100)
                                            } else {
                                                Color.gray
                                                    .frame(width: 100, height: 100)
                                            }
                                        }
                                        Text("Submitted at: \(selectedDate.formatted(date: .numeric, time: .omitted))")
                                    }
                                }
                            } else {
                                Text("No images available for selected date.")
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding()
                    }
                }
            }
        }
        .padding()
    }
    
    func fetchFacilities() {
        isLoading = true
        FirebaseManager.shared.fetchFacilities { result in
            isLoading = false
            switch result {
            case .success(let facilities):
                self.facilities = facilities
                if let latestFacility = facilities.sorted(by: { $0.submittedAt > $1.submittedAt }).first {
                    self.selectedFacility = latestFacility
                    self.fetchUsers()
                }
            case .failure(let error):
                self.errorMessage = "Failed to load facilities: \(error.localizedDescription)"
            }
        }
    }
    
    func fetchUsers() {
        guard let facility = selectedFacility else {
            errorMessage = "Please select a facility."
            return
        }
        
        isLoading = true
        FirebaseManager.shared.db.child("users").queryOrdered(byChild: "facility_id").queryEqual(toValue: facility.id).observeSingleEvent(of: .value) { snapshot in
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
            self.users = users
            self.fetchImages()
            isLoading = false
        } withCancel: { error in
            self.errorMessage = "Failed to load users: \(error.localizedDescription)"
            isLoading = false
        }
    }
    
    func fetchImages() {
        guard let facility = selectedFacility else {
            errorMessage = "Please select a facility."
            return
        }
        
        isLoading = true
        images = [:]
        
        for user in users {
            FirebaseManager.shared.db.child("users").child(user.id).child("images").observeSingleEvent(of: .value) { snapshot in
                var userImages: [URL] = []
                let group = DispatchGroup()
                
                for child in snapshot.children {
                    if let childSnapshot = child as? DataSnapshot,
                       let imageData = childSnapshot.value as? [String: Any],
                       let imagePath = imageData["image_url"] as? String,
                       let submittedAt = imageData["submitted_at"] as? Double {
                        let imageDate = Date(timeIntervalSince1970: submittedAt)
                        let calendar = Calendar.current
                        if calendar.isDate(imageDate, inSameDayAs: selectedDate) {
                            group.enter()
                            FirebaseManager.shared.fetchImageURL(imagePath: imagePath) { result in
                                switch result {
                                case .success(let url):
                                    userImages.append(url)
                                case .failure(let error):
                                    print("Failed to fetch image URL: \(error)")
                                }
                                group.leave()
                            }
                        }
                    }
                }
                
                group.notify(queue: .main) {
                    self.images[user.id] = userImages
                    isLoading = false
                }
            } withCancel: { error in
                self.errorMessage = "Failed to load images: \(error.localizedDescription)"
                isLoading = false
            }
        }
    }
}

struct ImageListView_Previews: PreviewProvider {
    static var previews: some View {
        ImageListView()
    }
}
