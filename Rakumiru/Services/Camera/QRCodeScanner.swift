//
//  QRCodeScanner.swift
//  Rakumiru
//
//  Created by tetsu.kuribayashi on 2024/06/09.
//

import Foundation

class QRCodeScanner {
    static func decodeQRCode(from string: String) -> UserQRCode? {
        guard let data = string.data(using: .utf8) else { return nil }
        let decoder = JSONDecoder()
        return try? decoder.decode(UserQRCode.self, from: data)
    }
}
