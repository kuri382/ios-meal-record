//
//  Settings.swift
//  Rakumiru
//
//  Created by tetsu.kuribayashi on 2024/06/03.
//

import Foundation

class Config {
    static var OpenAIApiKey: String {
        guard let path = Bundle.main.path(forResource: "Config", ofType: "plist"),
              let xml = FileManager.default.contents(atPath: path),
              let plist = try? PropertyListSerialization.propertyList(from: xml, options: .mutableContainersAndLeaves, format: nil) as? [String: Any] else {
            fatalError("Config.plist file not found")
        }
        
        return plist["OPENAI_API_KEY"] as? String ?? ""
    }
    
    static var FirebaseDbUrl: String {
        guard let path = Bundle.main.path(forResource: "Config", ofType: "plist"),
              let xml = FileManager.default.contents(atPath: path),
              let plist = try? PropertyListSerialization.propertyList(from: xml, options: .mutableContainersAndLeaves, format: nil) as? [String: Any] else {
            fatalError("Config.plist file not found")
        }
        
        return plist["FIREBASE_DB_URL"] as? String ?? ""
    }
}
