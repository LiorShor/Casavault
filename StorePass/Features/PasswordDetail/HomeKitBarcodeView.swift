//
//  HomeKitBarcodeView.swift
//  StorePass
//
//  Created by Lior Shor on 28/02/2026.
//

import SwiftUI
import CoreImage.CIFilterBuiltins

struct HomeKitBarcodeView: View {
    let code: String
    let qrCodePayload: String? // The actual scanned QR code payload
    
    @State private var ciContext = CIContext()
    
    private enum CodeType {
        case homeKit // 8 digits
        case matter  // 11 digits
        case unknown
    }
    
    private var codeType: CodeType {
        let digits = code.filter { $0.isNumber }
        switch digits.count {
        case 8:
            return .homeKit
        case 11:
            return .matter
        default:
            return .unknown
        }
    }
    
    private var formattedCode: String {
        // Remove any non-digit characters
        let digits = code.filter { $0.isNumber }
        
        switch codeType {
        case .homeKit:
            // HomeKit format: XXX-XX-XXX (8 digits)
            let paddedDigits = String(digits.prefix(8).padding(toLength: 8, withPad: "0", startingAt: 0))
            let index1 = paddedDigits.index(paddedDigits.startIndex, offsetBy: 3)
            let index2 = paddedDigits.index(paddedDigits.startIndex, offsetBy: 5)
            let part1 = paddedDigits[..<index1]
            let part2 = paddedDigits[index1..<index2]
            let part3 = paddedDigits[index2...]
            return "\(part1)-\(part2)-\(part3)"
            
        case .matter:
            // Matter format: XXXX-XXX-XXXX (11 digits)
            let paddedDigits = String(digits.prefix(11).padding(toLength: 11, withPad: "0", startingAt: 0))
            let index1 = paddedDigits.index(paddedDigits.startIndex, offsetBy: 4)
            let index2 = paddedDigits.index(paddedDigits.startIndex, offsetBy: 7)
            let part1 = paddedDigits[..<index1]
            let part2 = paddedDigits[index1..<index2]
            let part3 = paddedDigits[index2...]
            return "\(part1)-\(part2)-\(part3)"
            
        case .unknown:
            return digits
        }
    }
    
    // Generate QR Code payload
    private var qrPayload: String {
        let cleanCode = formattedCode.replacingOccurrences(of: "-", with: "")
        
        switch codeType {
        case .homeKit:
            // HomeKit QR code format with proper encoding
            guard let codeValue = UInt(cleanCode) else { return "X-HM://000000000" }
            return encodeHomeKitSetupCode(code: codeValue, category: 1) // Category 1 = Other
            
        case .matter:
            // Matter QR code format: MT:YXXX...
            // This is a simplified version, real Matter codes have more complexity
            return "MT:\(cleanCode)"
            
        case .unknown:
            return cleanCode
        }
    }
    
    // Encode HomeKit setup code according to HAP specification
    private func encodeHomeKitSetupCode(code: UInt, category: UInt) -> String {
        let version: UInt = 0      // Version (3 bits, bits 42-44)
        let reserved: UInt = 0     // Reserved (4 bits, bits 38-41)
        let flags: UInt = 2        // Flags (4 bits, bits 27-30) - 2 means IP connectivity
        
        // Bit layout:
        // bits 0-26: setup code (27 bits)
        // bits 27-30: flags (4 bits)
        // bits 31-37: category (8 bits)
        // bits 38-41: reserved (4 bits)
        // bits 42-44: version (3 bits)
        
        // Combine reserved and version
        let resAndVer = (reserved & 0xf) | ((version << 4) & 0x70)
        
        // Combine category, reserved, and version
        let catResAndVer = (category & 0xff) | ((resAndVer & 0xff) << 8)
        
        // Combine flags with category/reserved/version
        let other = (flags & 0xf) | ((catResAndVer & 0xffff) << 4)
        
        // Final combination: shift other to high bits and OR with setup code
        let resnum = ((other & 0x1ffff) << 27) | (code & 0x7ffffff)
        
        // Convert to base36 (uppercase)
        var outString = String(resnum, radix: 36, uppercase: true)
        
        // Pad to 9 characters
        while outString.count < 9 {
            outString.insert("0", at: outString.startIndex)
        }
        
        // Generate a Setup ID (4 characters, alphanumeric)
        // This should ideally be stored per device, but for now we'll generate one based on the code
        let setupId = generateSetupId(from: code)
        
        return "X-HM://\(outString)\(setupId)"
    }
    
    // Generate a 4-character Setup ID from the pairing code
    private func generateSetupId(from code: UInt) -> String {
        // Use the code to generate a consistent 4-character ID
        // Convert to base36 and take last 4 characters (padded if needed)
        var setupId = String(code, radix: 36, uppercase: true)
        
        // Ensure exactly 4 characters
        if setupId.count > 4 {
            setupId = String(setupId.suffix(4))
        } else {
            while setupId.count < 4 {
                setupId = "0" + setupId
            }
        }
        
        return setupId
    }
    
    private func generateQRCode(from string: String) -> UIImage {
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(string.utf8)
        // Use high error correction for better scanning
        filter.correctionLevel = "H"
        
        if let outputImage = filter.outputImage {
            // Scale up the QR code for better quality
            let transform = CGAffineTransform(scaleX: 10, y: 10)
            let scaledImage = outputImage.transformed(by: transform)
            
            if let cgImage = ciContext.createCGImage(scaledImage, from: scaledImage.extent) {
                return UIImage(cgImage: cgImage)
            }
        }
        
        return UIImage(systemName: "xmark.circle") ?? UIImage()
    }
    
    var body: some View {
        if let payload = qrCodePayload {
            // Show scanned QR code
            VStack(spacing: 16) {
                // QR Code from scanned payload with logo overlay for Matter codes
                Image(uiImage: generateQRCode(from: payload))
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200, height: 200)
                    .overlay {
                        if codeType == .matter {
                            // Matter logo overlay in center
                            ZStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.white)
                                    .frame(width: 40, height: 40)
                                
                                Image(systemName: "apple.homekit")
                                    .font(.system(size: 24, weight: .medium))
                                    .foregroundStyle(.black)
                            }
                        }
                    }
                    .padding(12)
                    .background(Color.white)
                    .clipShape(.rect(cornerRadius: 12))
                
                // The formatted code below with icon if Matter
                HStack(spacing: 12) {
                    if codeType == .matter {
                        // Matter icon
                        Image(systemName: "matter.logo")
                            .font(.title2)
                            .foregroundStyle(.primary)
                    }
                    
                    Text(formattedCode)
                        .font(.system(.title2, design: .monospaced))
                        .fontWeight(.medium)
                        .tracking(2)
                }
            }
            .padding(.vertical, 20)
            .frame(maxWidth: .infinity)
        } else {
            // No QR code scanned - don't show anything
            EmptyView()
        }
    }
}

#Preview {
    VStack(spacing: 30) {
        // HomeKit 8-digit code with scanned payload
        HomeKitBarcodeView(code: "12345678", qrCodePayload: "X-HM://0021YCYEP3QYT")
        
        // Matter 11-digit code with scanned payload
        HomeKitBarcodeView(code: "06071222023", qrCodePayload: "MT:06071222023")
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
