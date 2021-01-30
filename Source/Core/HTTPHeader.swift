//
//  HTTPHeader.swift
//  HttpMessenger
//
//  Created by Yuto on 2020/12/17.
//

import Foundation

public class HTTPHeaders: NSObject {
    private var headers: [HTTPHeader]? = nil
    
    public init(_ headers: [HTTPHeader]? = nil) {
        super.init()
        if let headers = headers {
            append(headers)
        }
    }
    
    public init(_ headers: HTTPHeaders? = nil) {
        super.init()
        if let headers = headers {
            append(headers)
        }
    }
    
    func append(_ header: HTTPHeader) -> Int? {
        if headers == nil {
            headers = []
        }
        headers?.append(header)
        return headers?.firstIndex(of: header)
    }
    
    func append(_ headers: [HTTPHeader]) {
        if self.headers == nil {
            self.headers = []
        }
        self.headers?.append(contentsOf: headers)
    }
    
    func append(_ headers: HTTPHeaders) {
        if let headers = headers.headers {
            append(headers)
        }
    }
    
    func remove(_ forHeaderKey: String) -> Bool {
        var removed = false
        let targets = headers?.filter{ ($0).key == forHeaderKey }
        if let targets = targets {
            for header in targets {
                if let index = headers?.firstIndex(of: header) {
                    headers?.remove(at: index)
                    removed = true
                }
            }
        }
        return removed
    }
    
    func removeAll() {
        headers?.removeAll()
    }
    
    func convert() -> [String : String]? {
        return HTTPHeaders.convert(self)
    }
    
    static func convert(_ headers: HTTPHeaders?) -> [String : String]? {
        if let headers = headers?.headers {
            var ret: [String : String] = [:]
            for header in headers {
                ret.updateValue(header.value, forKey: header.key)
            }
            return ret
        } else {
            return nil
        }
    }
}

public class HTTPHeader: NSObject {
    public let key: String
    private (set) public var value: String
    
    public init(_ value: String, forHeaderKey: String) {
        self.key = forHeaderKey
        self.value = value
    }
    
    func update(_ value: String) {
        self.value = value
    }
    
    func convert() -> [String : String]? {
        return HTTPHeader.convert(self)
    }
    
    static func convert(_ header: HTTPHeader?) -> [String : String]? {
        if let header = header {
            return [header.key : header.value]
        } else {
            return nil
        }
    }
}
