//
//  ResponseModel.swift
//  HttpMessenger
//
//  Created by Yuto on 2020/12/11.
//

import Cocoa
import Alamofire

class ResponseModel: Codable {
    var statusCode: HttpStatus
    var contentType: ContentTypeModel
    var headers: Dictionary<String, String>? // without cookie
    var cookies: [String: String]?
    var cookieUrl: URL?
    var body: Data?
    
    init() {
        statusCode = .ok
        contentType = .JSON
        headers = nil
        cookies = nil
        cookieUrl = nil
        body = nil
    }
    
    init(_ response:HTTPURLResponse) {
        statusCode = HttpStatus(rawValue: response.statusCode) ?? .badRequest
        contentType = ContentTypeModel(rawValue: (response.allHeaderFields["Content-Type"] as? String ?? ContentTypeModel.OTHERS.rawValue)) ?? .OTHERS
        headers = response.headers.dictionary
        if let responseHeaders = response.allHeaderFields as? [String: String] {
            cookies = ["Set-Cookie": responseHeaders["Set-Cookie"] ?? ""]
        }
    }
    
    init(_ statusCode: HttpStatus, contentType: ContentTypeModel, headers: Dictionary<String, String>?, cookieUrl: URL?, cookies: [String: String]?, body: Data?) {
        self.statusCode = statusCode
        self.contentType = contentType
        self.headers = headers
        self.cookies = cookies
        self.cookieUrl = cookieUrl
        self.body = body
    }
    
    func header(_ key: String) -> String? {
        var ret: String?
        if let headersTmp = headers, let val = headersTmp[key] {
            ret = val
        }
        return ret
    }
    
    func stringBody(_ endode:String.Encoding = .utf8) -> String? {
        var ret: String?
        if let tmp = body {
            ret = String.init(data: tmp, encoding: endode)
        }
        return ret
    }
    
    func asHTTPCookie() -> [HTTPCookie]? {
        var ret: [HTTPCookie]?
        if let url = cookieUrl, let cookie = cookies, !(cookie.isEmpty) {
            ret = HTTPCookie.cookies(withResponseHeaderFields: cookie, for: url)
        }
        return ret
    }
}
