//
//  UserDetailView.swift
//  Rakumiru
//
//  Created by tetsu.kuribayashi on 2024/06/09.
//

import Foundation
import SwiftUI

struct UserDetailView: View {
    var user: User
    var userImages: [ImageData]
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("\(user.userName)さん")
                .font(.largeTitle)
                .padding(.bottom, 10)
            
            List(userImages) { image in
                ImageView(image: image)
            }
        }
        .navigationTitle("利用者様詳細情報")
        .padding()
    }
}
