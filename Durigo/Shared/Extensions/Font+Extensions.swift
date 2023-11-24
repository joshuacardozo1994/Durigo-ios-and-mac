//
//  Font+Extensions.swift
//  Durigo
//
//  Created by Joshua Cardozo on 24/11/23.
//

import SwiftUI

extension Font {
    static func dancingScriptBold(size: CGFloat) -> Font {
        self.custom("DancingScript-Bold", size: size)
    }
    
    static func poppinsMedium(size: CGFloat) -> Font {
        self.custom("Poppins-Medium", size: size)
    }
    
    static func poppinsBold(size: CGFloat) -> Font {
        self.custom("Poppins-Bold", size: size)
    }
    
    static func cormorantGaramondBold(size: CGFloat) -> Font {
        self.custom("CormorantGaramond-Bold", size: size)
    }
}
