//
//  ContentView.swift
//  Rakumiru
//
//  Created by tetsu.kuribayashi on 2024/06/03.
//

import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 40) {
                    VStack(spacing: 20) {
                        Text("つかう")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(Color(hex: "262260"))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.leading)
                        
                        NavigationCardView(destination: SingleAnalyzeView(), iconName: "photo", title: "一枚分析モード")
                        NavigationCardView(destination: ContinuousAnalyzeView(), iconName: "gobackward", title: "連続読み取りモード")
                        NavigationCardView(destination: ImageListView(), iconName: "folder", title: "記録結果を見る")
                    }
                    
                    VStack(spacing: 20) {
                        Text("設定")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(Color(hex: "262260"))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.leading)
                        
                        NavigationCardView(destination: FacilityRegistrationView(), iconName: "rectangle.and.pencil.and.ellipsis", title: "施設情報の編集")
                        NavigationCardView(destination: UserRegistrationView(), iconName: "person.circle", title: "ユーザー情報の編集")
                    }
                }
                .padding()
            }
            .navigationTitle("食事記録")
            .background(Color(.systemBackground).edgesIgnoringSafeArea(.all))
        }
    }
}

struct NavigationCardView<Destination: View>: View {
    let destination: Destination
    let iconName: String
    let title: String
    
    var body: some View {
        NavigationLink(destination: destination) {
            HStack {
                Image(systemName: iconName)
                    .font(.title)
                    .foregroundColor(Color(hex: "262260"))
                    .frame(width: 50, alignment: .leading)
                Text(title)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(Color(hex: "262260"))
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.title2)
                    .foregroundColor(Color("262260"))
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(10)
            .shadow(color: Color(.systemGray4), radius: 5, x: 0, y: 2)
            .padding(.horizontal)
        }
    }
}

// 以下はダミービューの例です。実際の実装に置き換えてください。
struct ItemListView: View {
    var body: some View {
        Text("Item List View")
    }
}


private let itemFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .medium
    return formatter
}()

#Preview {
    ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
