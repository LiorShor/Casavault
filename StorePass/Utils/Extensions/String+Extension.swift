//
//  String+Extension.swift
//  StorePass
//
//  Created by Lior Shor on 22/01/2026.
//

import Foundation

extension String {
    static var empty = ""

    // Parses a HomeKit QR code payload (X-HM://...) and returns the 8-digit setup code string.
    // HAP spec: the setup payload is always the first 9 base-36 chars after the X-HM:// prefix.
    // Bits 0-26 of that 9-char value contain the pairing code (27-bit, up to 99999999).
    // Longer URLs (HomeKit-over-Matter) have additional data after the 9-char block — we ignore it.
    // Falls back to filtering digits directly from the payload for other formats.
    static func parseQRCode(_ payload: String) -> String {
        if payload.hasPrefix("X-HM://") {
            let afterPrefix = payload.dropFirst(7)
            let encoded = String(afterPrefix.prefix(9)).lowercased()
            guard encoded.count == 9 else { return payload.filter { $0.isNumber } }
            var value: UInt64 = 0
            var valid = true
            for char in encoded {
                let ascii = char.asciiValue ?? 0
                let digit: UInt64
                if ascii >= 48 && ascii <= 57 {
                    digit = UInt64(ascii - 48)
                } else if ascii >= 97 && ascii <= 122 {
                    digit = UInt64(ascii - 87)
                } else {
                    valid = false
                    break
                }
                value = value * 36 + digit
            }
            if valid {
                let pin = Int(value & 0x7FFFFFF)
                if pin > 0 && pin <= 99_999_999 {
                    return String(format: "%08d", pin)
                }
            }
        }
        return payload.filter { $0.isNumber }
    }
}
