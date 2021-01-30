//
//  QueryRequestSerializer.swift
//  HttpMessenger
//
//  Created by Yuto on 2021/01/13.
//

import Foundation

public protocol QueryRequestSerializer: RequestSerializer {
    func encode(_ data: Any?) throws -> [URLQueryItem]?
}

public class URLQueryRequestSerialiser: QueryRequestSerializer {
    public let contentType: String?
    public let cachePolicy: URLRequest.CachePolicy
    public let timeoutInterval: TimeInterval
    public var forcedBodyWhenGet: Bool = false
    public static var `default`: URLQueryRequestSerialiser {
        return URLQueryRequestSerialiser()
    }
    
    required public init(contentType: String? = "application/x-www-form-urlencoded",
                         timeoutInterval: TimeInterval = TimeInterval(10),
                         cachePolicy: URLRequest.CachePolicy = .useProtocolCachePolicy) {
        self.contentType = contentType
        self.timeoutInterval = timeoutInterval
        self.cachePolicy = cachePolicy
    }
    
    public func encode(_ data: Any?) throws -> Data? {
        throw HttpMessengerError.encoderError
    }
    
    public func encode(_ data: Any?) throws -> [URLQueryItem]? {
        var ret: [URLQueryItem]? = nil
        if data == nil {
            // NOP
        } else if data is [String : String], let data = data as? [String : String] {
            ret = []
            for d in data {
                ret?.append(URLQueryItem(name: d.0, value: d.1))
            }
        } else {
            throw HttpMessengerError.invalidSerializedType
        }
        return ret
    }
}
