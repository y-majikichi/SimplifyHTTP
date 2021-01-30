//
//  HttpMessengerSession+Advanced.swift
//  HttpMessenger
//
//  Created by Yuto on 2021/01/12.
//

import Foundation

/// Advanced
public extension HttpMessengerSession {
    func setTrustManagerDelegate(_ trustManager: TrustManagerDelegate?) {
        sessionDelegate?.trustManagerDelegate = trustManager
    }
}
