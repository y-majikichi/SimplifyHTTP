//
//  RequestSerializer.swift
//  HttpMessenger
//
//  Created by Yuto on 2020/12/17.
//

import Foundation

public protocol RequestSerializer {
    var contentType: String? { get }
    var timeoutInterval: TimeInterval { get }
    var cachePolicy: URLRequest.CachePolicy { get }
    var forcedBodyWhenGet: Bool { get }
    
    init(contentType: String?,
         timeoutInterval: TimeInterval,
         cachePolicy: URLRequest.CachePolicy)
    
    func encode(_ data:Any?) throws -> Data?
}

public class DataSerializer: RequestSerializer {
    public let contentType: String?
    public let cachePolicy: URLRequest.CachePolicy
    public let timeoutInterval: TimeInterval
    public var forcedBodyWhenGet: Bool = false
    public static var `default`: DataSerializer {
        return DataSerializer()
    }
    
    required public init(contentType: String? = nil,
                         timeoutInterval: TimeInterval = TimeInterval(10),
                         cachePolicy: URLRequest.CachePolicy = .useProtocolCachePolicy) {
        self.contentType = contentType
        self.timeoutInterval = timeoutInterval
        self.cachePolicy = cachePolicy
    }
    
    public func encode(_ data: Any?) throws -> Data? {
        if data == nil {
            // NOP
            return nil
        } else if let data = data as? Data {
            return data
        } else {
            throw HttpMessengerError.invalidSerializedType
        }
    }
}

public class StringSerializer: RequestSerializer {
    public let contentType: String?
    public let cachePolicy: URLRequest.CachePolicy
    public let timeoutInterval: TimeInterval
    public let encoding: String.Encoding
    public var forcedBodyWhenGet: Bool = false
    public static var `default`: StringSerializer {
        return StringSerializer()
    }
    
    required public convenience init(contentType: String? = "text/plain",
                         timeoutInterval: TimeInterval = TimeInterval(10),
                         cachePolicy: URLRequest.CachePolicy = .useProtocolCachePolicy) {
        self.init(contentType: contentType, timeoutInterval: timeoutInterval, cachePolicy: cachePolicy, encoding: .utf8)
    }
    
    init(contentType: String? = "text/plain",
                         timeoutInterval: TimeInterval = TimeInterval(10),
                         cachePolicy: URLRequest.CachePolicy = .useProtocolCachePolicy,
                         encoding: String.Encoding = .utf8) {
        self.contentType = contentType
        self.timeoutInterval = timeoutInterval
        self.cachePolicy = cachePolicy
        self.encoding = encoding
    }
    
    public func encode(_ data: Any?) throws -> Data? {
        if data == nil {
            // NOP
            return nil
        } else if let string = data as? String {
            if let encoded = string.data(using: self.encoding) {
                return encoded
            } else {
                throw HttpMessengerError.invalidSerializedType
            }
        } else {
            throw HttpMessengerError.invalidSerializedType
        }
    }
}

public class JSONSerializer: RequestSerializer {
    public let contentType: String?
    public let cachePolicy: URLRequest.CachePolicy
    public let timeoutInterval: TimeInterval
    let wirtingOptions: JSONSerialization.WritingOptions
    public var forcedBodyWhenGet: Bool = false
    public static var `default`: JSONSerializer {
        return JSONSerializer()
    }
    
    required public convenience init(contentType: String? = "application/json",
                                     timeoutInterval: TimeInterval = TimeInterval(10),
                                     cachePolicy: URLRequest.CachePolicy = .useProtocolCachePolicy) {
        self.init(contentType: contentType, timeoutInterval: timeoutInterval, cachePolicy: cachePolicy, options: .fragmentsAllowed)
    }
    
    init(contentType: String? = "application/json",
         timeoutInterval: TimeInterval = TimeInterval(10),
         cachePolicy: URLRequest.CachePolicy = .useProtocolCachePolicy,
         options: JSONSerialization.WritingOptions = .fragmentsAllowed) {
        self.contentType = contentType
        self.timeoutInterval = timeoutInterval
        self.cachePolicy = cachePolicy
        self.wirtingOptions = options
    }
    
    public func encode(_ data: Any?) throws -> Data? {
        if let data = data {
            return try JSONSerialization.data(withJSONObject: data, options: wirtingOptions)
        } else {
            return nil
        }
    }
}

