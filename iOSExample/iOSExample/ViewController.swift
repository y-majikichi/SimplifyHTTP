//
//  ViewController.swift
//  iOSExample
//
//  Created by Yuto on 2021/01/03.
//

import UIKit
import HttpMessenger

class ViewController: UIViewController {
    
    @IBOutlet weak var getButton: UIButton!
    @IBOutlet weak var getRequestWithBasicAuthButton: UIButton!
    @IBOutlet weak var getImageRequest: UIButton!
    @IBOutlet weak var donwloadTaskButton: UIButton!
    @IBOutlet weak var responseTextView: UITextView!
    @IBOutlet weak var responseImageView: UIImageView!
    
    @IBAction func getButtonTaped(_ sender: UIButton) {
        // get
        _ = HMSession.request(URL(string: "")!,
                              methodType: .get,
                              success: { [self] (session, request, response, data) in
                                responseTextView.text = "get Request OK"
                              },
                              failure: { [self] (session, request, response, error) in
                                responseTextView.text = "get Request Failed"
                              })
    }
    
    @IBAction func getWithAuthTapped(_ sender: UIButton) {
        // get
        // 認証情報
        let username = ""
        let password = ""
        // リクエスト準備
        guard let credentialData = "\(username):\(password)".data(using: String.Encoding.utf8) else { return }
        let credential = credentialData.base64EncodedString(options: [])
        let basicData = "Basic \(credential)"
        var headers: [String : String] = [:]
        headers.updateValue(basicData, forKey: "Authorization")
        
        HMSession.setTrustManagerDelegate(self)
        
        _ = HMSession.request(URL(string: "")!,
                              methodType: .get,
                              headers: headers,
                              success: { [self] (session, request, response, data) in
                                responseTextView.text = "get Request with Basic Auth OK"
                              },
                              failure: { [self] (session, request, response, error) in
                                responseTextView.text = "get Request with Basic Auth Failed"
                              })
    }
    
    @IBAction func getImageRequestTapped(_ sender: UIButton) {
        // Image
        _ = HMSession.request(URL(string: "")!,
                              methodType: .get,
                              responseDeserializer: DataDeserializer.default,
                              success: { [self] (session, request, response, data) in
                                responseImageView.image = UIImage.init(data: data as! Data)
                              },
                              failure: { [self] (session, request, response, error) in
                                responseTextView.text = "get Request Failed"
                              })
    }
    
    @IBAction func dounloadTaskTapped(_ sender: Any) {
        // Download
        _ = HMSession.download(URL(string: "")!,
                               methodType: .get,
                               responseDeserializer: DataDownloadResponseDeserializer(URL(fileURLWithPath: NSHomeDirectory() + "/Documents/tmp.tmp")),
                               success: { [self] (session, request, response, data) in
                                do {
                                    responseTextView.text = "Download OK \n\((data as! URL).absoluteString)"
                                    responseImageView.image = try UIImage.init(data: Data.init(contentsOf: data as! URL))
                                } catch {
                                    responseTextView.text = "Download OK \n\((data as! URL).absoluteString), but failed decode " + error.localizedDescription
                                }
                               }, failure: { [self] (session, request, response, error) in
                                responseTextView.text = "Download Failed"
                               })
    }
    
}

extension ViewController: TrustManagerDelegate {
    func trustManager(_ session: URLSession,
                      didReceive challenge: URLAuthenticationChallenge,
                      completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        let credit = URLCredential(user: "",
                                   password: "",
                                   persistence: .forSession)
        completionHandler(.useCredential, credit)
    }
    
    func trustManager(_ session: URLSession,
                      task: URLSessionTask,
                      didReceive challenge: URLAuthenticationChallenge,
                      completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        let credit = URLCredential(user: "",
                                   password: "",
                                   persistence: .forSession)
        completionHandler(.useCredential, credit)
    }
}
