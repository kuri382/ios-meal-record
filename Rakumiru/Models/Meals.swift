//
//  Meals.swift
//  Rakumiru
//
//  Created by tetsu.kuribayashi on 2024/06/08.
//

import Foundation

struct Meal: Codable, Identifiable {
    var id: UUID = UUID()
    let name: String
    let nutrients: String
    let weight: Int64
    let label: String
    let remaining: Double

    enum CodingKeys: String, CodingKey {
        case name, nutrients, weight, label, remaining
    }
}

struct MealsData: Codable {
    let meals: [Meal]
}
