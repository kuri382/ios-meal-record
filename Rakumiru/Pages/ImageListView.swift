import SwiftUI

import SwiftUI

struct ImageListView: View {
    @StateObject private var viewModel = ImageListViewModel()
    @State private var selectedDate: Date = Date()
    
    var body: some View {
        VStack {
            if viewModel.facilities.isEmpty {
                ProgressView("Loading...")
                    .onAppear {
                        viewModel.fetchFacilities()
                    }
            } else {
                Picker("施設選択", selection: $viewModel.selectedFacility) {
                    ForEach(viewModel.facilities) { facility in
                        Text(facility.facilityName).tag(facility as Facility?)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .onChange(of: viewModel.selectedFacility) { newFacility in
                    if let facility = newFacility {
                        viewModel.fetchUsers(for: facility)
                    }
                }
                
                DatePicker("日付選択", selection: $selectedDate, displayedComponents: .date)
                    .padding()
                    .onChange(of: selectedDate) { _ in
                        viewModel.fetchImages(for: selectedDate)
                    }
                
                if viewModel.isLoading {
                    ProgressView("Loading data...")
                } else if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding()
                } else {
                    UserListView(users: $viewModel.users, images: $viewModel.images, selectedDate: selectedDate)
                }
                
                Button(action: {
                    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                       let rootViewController = windowScene.windows.first?.rootViewController {
                        viewModel.sendEmail(selectedDate: selectedDate, presentingViewController: rootViewController)
                    }
                }) {
                    Text("メール送信")
                }
                .padding()
            }
        }
    }
}

struct UserListView: View {
    @Binding var users: [User]
    @Binding var images: [String: [ImageData]]
    var selectedDate: Date
    
    var body: some View {
        List(users) { user in
            if let userImages = images[user.id], !userImages.isEmpty {
                NavigationLink(destination: UserDetailView(user: user, userImages: userImages)) {
                    VStack(alignment: .leading) {
                        Text("\(user.userName)さん")
                            .font(.headline)
                        if let firstImage = userImages.first {
                            ImageView(image: firstImage)
                        }
                    }
                    .padding(.vertical, 5)
                }
            } else {
                VStack(alignment: .leading) {
                    Text(user.userName)
                        .font(.headline)
                    Text("No images available for selected date.")
                        .foregroundColor(.gray)
                }
                .padding(.vertical, 5)
            }
        }
    }
}

struct ImageView: View {
    var image: ImageData
    
    var formattedDate: String {
        let date = Date(timeIntervalSince1970: image.submittedAt / 1000)
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd HH:mm"
        return formatter.string(from: date)
    }
    
    var stapleAverage: Double {
        let staples = image.meals?.filter { $0.label == "staple" } ?? []
        let totalRemaining = staples.reduce(0.0) { $0 + $1.remaining }
        return staples.isEmpty ? 0.0 : (totalRemaining / Double(staples.count)) * 100
    }
    
    var sideAverage: Double {
        let sides = image.meals?.filter { $0.label == "side" } ?? []
        let totalRemaining = sides.reduce(0.0) { $0 + $1.remaining }
        return sides.isEmpty ? 0.0 : (totalRemaining / Double(sides.count)) * 100
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                AsyncImage(url: URL(string: image.imageUrl)) { phase in
                    if let image = phase.image {
                        image.resizable()
                            .scaledToFill()
                            .frame(width: 100, height: 100)
                            .clipped()
                            .rotationEffect(.degrees(-90))
                            .cornerRadius(10)
                    } else if phase.error != nil {
                        Color.red
                            .frame(width: 100, height: 100)
                    } else {
                        Color.gray
                            .frame(width: 100, height: 100)
                    }
                }
                Text("記録時刻: \(formattedDate)")
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if let meals = image.meals {
                Text("主菜の残食率: \(String(format: "%.0f", stapleAverage))%")
                    .font(.subheadline)
                    .foregroundColor(.primary)
                    .bold()
                ProgressView(value: stapleAverage, total: 100)
                    .progressViewStyle(LinearProgressViewStyle(tint: .red))
                    .frame(height: 10)
                    .padding(.bottom, 10)
                Text("副菜の残食率: \(String(format: "%.0f", sideAverage))%")
                    .font(.subheadline)
                    .foregroundColor(.primary)
                    .bold()
                ProgressView(value: sideAverage, total: 100)
                    .progressViewStyle(LinearProgressViewStyle(tint: .red))
                    .frame(height: 10)
                    .padding(.bottom, 10)
                Divider()
                ForEach(meals) { meal in
                    Text("\(meal.name): \(meal.weight)g (\(meal.label == "staple" ? "主菜" : (meal.label == "side" ? "副菜" : meal.label)), \(Int(meal.remaining * 100))%)")
                        .font(.subheadline)
                }
            }
        }
        .padding(.vertical, 5)
    }
}

class ImageListViewModel: ObservableObject {
    @Published var selectedFacility: Facility?
    @Published var facilities: [Facility] = []
    @Published var users: [User] = []
    @Published var images: [String: [ImageData]] = [:]
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var latestImages: [ImageData] = []
    
    func fetchFacilities() {
        isLoading = true
        FirebaseManager.shared.fetchFacilities { result in
            DispatchQueue.main.async {
                self.isLoading = false
                switch result {
                case .success(let facilities):
                    self.facilities = facilities
                    if let firstFacility = facilities.first {
                        self.selectedFacility = firstFacility
                        self.fetchUsers(for: firstFacility)
                    } else {
                        self.errorMessage = "No facilities found."
                    }
                case .failure(let error):
                    self.errorMessage = "Failed to load facilities: \(error.localizedDescription)"
                }
            }
        }
    }
    
    func fetchUsers(for facility: Facility) {
        isLoading = true
        print("Fetching users for facility: \(facility.facilityName)") // デバッグログ
        FirebaseManager.shared.fetchUsers(for: facility.id) { result in
            DispatchQueue.main.async {
                self.isLoading = false
                switch result {
                case .success(let users):
                    print("Users fetched: \(users)") // デバッグログ
                    self.users = users
                    self.errorMessage = nil // エラーメッセージをクリア
                    self.fetchImages(for: Date()) // ユーザーのフェッチ後に画像をフェッチ
                case .failure(let error):
                    self.errorMessage = "Failed to load users: \(error.localizedDescription)"
                    print("Error fetching users: \(error.localizedDescription)") // デバッグログ
                }
            }
        }
    }
    
    func fetchImages(for date: Date) {
        guard !users.isEmpty else {
            errorMessage = "No users found."
            return
        }
        
        isLoading = true
        images = [:]
        
        let group = DispatchGroup()
        
        for user in users {
            group.enter()
            FirebaseManager.shared.fetchImages(for: user.id) { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let userImages):
                        let calendar = Calendar.current
                        let filteredImages = userImages.filter {
                            calendar.isDate(Date(timeIntervalSince1970: $0.submittedAt / 1000), inSameDayAs: date)
                        }
                        let latestImage = filteredImages.sorted(by: { $0.submittedAt > $1.submittedAt }).first
                        self.images[user.id] = latestImage != nil ? [latestImage!] : []
                    case .failure(let error):
                        self.errorMessage = "Failed to load images: \(error.localizedDescription)"
                    }
                    group.leave()
                }
            }
        }
        
        group.notify(queue: .main) {
            self.isLoading = false
        }
    }
    
    
    func filterLatestImages(for date: Date) {
        var latestImages: [ImageData] = []
        let calendar = Calendar.current
        
        for userImages in images.values {
            if let latestImage = userImages.filter({ calendar.isDate(Date(timeIntervalSince1970: $0.submittedAt / 1000), inSameDayAs: date) })
                .sorted(by: { $0.submittedAt > $1.submittedAt })
                .first {
                latestImages.append(latestImage)
            }
        }
        
        self.latestImages = latestImages
    }
    
    func sendEmail(selectedDate: Date, presentingViewController: UIViewController) {
        guard let facility = selectedFacility else {
            errorMessage = "Facility not selected."
            return
        }
        
        let csvData = EmailManager.shared.generateCSVData(for: images, users: users, facilityName: facility.facilityName)
        EmailManager.shared.sendEmail(csvData: csvData, facilityName: facility.facilityName, presentingViewController: presentingViewController)
    }
    
}

struct ImageListView_Previews: PreviewProvider {
    static var previews: some View {
        ImageListView()
    }
}
