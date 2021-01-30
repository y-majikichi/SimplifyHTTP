//
//  HTTPHeader.swift
//  HttpMessenger
//
//  Created by Yuto on 2020/12/17.
//

import Foundation

class HTTPHeader: NSObject {
    static let kKeyContentType = HeaderKey.contentType.rawValue
    
    static func convert(_ headers:[HTTPHeader]?) -> [String : String]? {
        return nil
    }
}
