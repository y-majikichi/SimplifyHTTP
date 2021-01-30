//
//  EncodableSerializer.swift
//  HttpMessenger
//
//  Created by Yuto on 2021/01/13.
//

import Foundation

public protocol EncodableSerializer: RequestSerializer {
    
    var encoder: Encoder { get }
    
    func encode<EncodableData: Encodable>(_ data: EncodableData?) throws -> Data?
}

public class JSONEncodableSerializer: EncodableSerializer {
    public var encoder: Encoder
    public var contentType: String?
    public var timeoutInterval: TimeInterval
    public var cachePolicy: URLRequest.CachePolicy
    public var forcedBodyWhenGet: Bool = false
    
    public required init(contentType: String? = "application/json",
                         timeoutInterval: TimeInterval = TimeInterval(10),
                         cachePolicy: URLRequest.CachePolicy = .useProtocolCachePolicy) {
        self.encoder = JSONEncoder() as! Encoder
        self.contentType = contentType
        self.timeoutInterval = timeoutInterval
        self.cachePolicy = cachePolicy
    }
    
    public func encode(_ data: Any?) throws -> Data? {
        throw HttpMessengerError.encoderError
    }
    
    public func encode<EncodableData: Encodable>(_ data: EncodableData?) throws -> Data? {
        guard let encodeData = data else {
            return nil
        }
        if let jsonEncoder = self.encoder as? JSONEncoder {
            return try jsonEncoder.encode(encodeData)
        } else {
            throw HttpMessengerError.encoderError
        }
    }
}
