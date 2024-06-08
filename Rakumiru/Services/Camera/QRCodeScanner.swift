//
//  QRCodeScanner.swift
//  Rakumiru
//
//  Created by tetsu.kuribayashi on 2024/06/09.
//

import Foundation

class QRCodeScanner {
    static func decodeQRCode(from string: String) -> UserQRCode? {
        if let data = string.data(using: .utf8) {
            let decoder = JSONDecoder()
            do {
                let userQRCode = try decoder.decode(UserQRCode.self, from: data)
                return userQRCode
            } catch {
                print("Failed to decode QR code data: \(error)")
                return nil
            }
        }
        return nil
    }
}
