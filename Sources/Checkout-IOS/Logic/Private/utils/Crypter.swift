//
//  Crypter.swift
//  Checkout-IOS
//
//  Created by MahmoudShaabanAllam on 23/04/2025.
//

import Foundation
/// Crypter helper class.
import SwiftyRSA
 class Crypter {
    
    // MARK: - Internal -
    // MARK: Methods
    
    /// Encrypts the given string using the given key.
    ///
    /// - Parameters:
    ///   - string: String to encrypt.
    ///   - key: Key to encrypt with.
    /// - Returns: String if the encryption succeed.
     static func encrypt(_ string: String, using key: String) -> String? {
        
        guard let publicKey = try? PublicKey(pemEncoded: key) else { return nil }
        guard let clear = try? ClearMessage(string: string, using: .utf8) else { return nil }
        
        var resultString = ""
        
        while true {
            guard let toEncryptData = try? clear.encrypted(with: publicKey, padding: .PKCS1) else { return nil }
            resultString = toEncryptData.base64String
            if !resultString.hasSuffix("AA==") {
                break
            }
        }
        
        return resultString
    }
    
    // MARK: - Private -
    // MARK: Methods
    
    //@available(*, unavailable) private init() { }
}
