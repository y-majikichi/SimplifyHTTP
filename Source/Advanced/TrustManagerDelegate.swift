//
//  TrustManager.swift
//  HttpMessenger
//
//  Created by Yuto on 2021/01/04.
//

import Foundation

public protocol TrustManagerDelegate: class {
    func trustManager(_ session: URLSession,
                      didReceive challenge: URLAuthenticationChallenge,
                      completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void)
    func trustManager(_ session: URLSession,
                      task: URLSessionTask,
                      didReceive challenge: URLAuthenticationChallenge,
                      completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void)
}
