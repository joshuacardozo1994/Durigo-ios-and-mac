//
//  Config.swift
//  Durigo
//
//  Created by Joshua Cardozo on 13/03/24.
//

import Foundation

#if PROD
let plistName = "config.prod"
#elseif LOCAL
let plistName = "config.local"
#elseif DEV
let plistName = "config.dev"
#endif
let path = Bundle.main.path(forResource: plistName, ofType: "plist")!
let dict = NSDictionary(contentsOfFile: path)!

struct Config {
    private init() {}
    static let shared = Config()
    
    let serverURL = dict.object(forKey: "SERVER_URL") as! String
}
