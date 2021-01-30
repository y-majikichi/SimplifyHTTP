//
//  RequestModel.swift
//  HttpMessenger
//
//  Created by Yuto on 2020/12/11.
//

import Cocoa

class RequestModel: Codable {
    var url: URL
    var contentType: ContentTypeModel?
    var headers: Dictionary<String, String>? // without cookie
    var cookies: [String: String]?
    var cookieUrl: URL?
    var parametersJson: String?
    
    init() {
        self.url = URL(string: "https://xxxxxx")!
    }
    
    init(_ url: URL, contentType: ContentTypeModel? = nil, headers: Dictionary<String, String>? = nil, cookies: [String: String]?, cookieUrl: URL?, parameters: Dictionary<String, Any>?) {
        self.url = url
        self.contentType = contentType
        self.headers = headers
        self.cookies = cookies
        self.cookieUrl = cookieUrl
        if let param = parameters {
            do {
                let data = try JSONSerialization.data(withJSONObject: param, options: .fragmentsAllowed)
                parametersJson = String.init(data: data, encoding: .utf8)
            } catch {
                parametersJson = nil
            }
        }
    }
}
