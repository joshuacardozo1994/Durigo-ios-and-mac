//
//  String+Extensions.swift
//  pdf test
//
//  Created by Joshua Cardozo on 14/10/23.
//
#if canImport(UIKit)
import UIKit
#else
import AppKit
#endif

extension String {
#if canImport(UIKit)
    func generateQRCode() -> UIImage? {
        let data = self.data(using: String.Encoding.ascii)
        
        if let filter = CIFilter(name: "CIQRCodeGenerator") {
            filter.setValue(data, forKey: "inputMessage")
            let transform = CGAffineTransform(scaleX: 3, y: 3)
            
            if let output = filter.outputImage?.transformed(by: transform) {
                return UIImage(ciImage: output)
            }
        }
        
        return nil
    }
#else
    func generateQRCode() -> NSImage? {
        return nil
    }
#endif
#if canImport(UIKit)
    func getQRCodeImage() -> UIImage? {
        guard let filter = CIFilter(name: "CIQRCodeGenerator") else { return nil }
        let data = self.data(using: .ascii, allowLossyConversion: false)
        filter.setValue(data, forKey: "inputMessage")
        guard let ciimage = filter.outputImage else { return nil }
        let transform = CGAffineTransform(scaleX: 10, y: 10)
        let scaledCIImage = ciimage.transformed(by: transform)
        let uiimage = UIImage(ciImage: scaledCIImage)
        return UIImage(data: uiimage.pngData()!)
    }
#else
    func getQRCodeImage() -> NSImage? {
        return nil
    }
#endif
}
