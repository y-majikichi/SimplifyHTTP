//
//  ResponseDeserializer.swift
//  HttpMessenger
//
//  Created by Yuto on 2020/12/17.
//

import Foundation

public protocol ResponseDeserializer {
    var acceptContentTypes: Set<String> { get set }
    func decode(_ data: Any?) throws -> Any?
}

public class JSONDeserializer: ResponseDeserializer {
    
    let readingOptions: JSONSerialization.ReadingOptions
    public var acceptContentTypes: Set<String> = ["application/json"]
    public static var `default`: JSONDeserializer {
        return JSONDeserializer()
    }
    
    public init(_ readingOptions: JSONSerialization.ReadingOptions = .allowFragments) {
        self.readingOptions = readingOptions
    }
    
    public func decode(_ data: Any?) throws -> Any? {
        if let data = data as? Data {
            return try JSONSerialization.jsonObject(with: data, options: readingOptions)
        } else {
            return nil
        }
    }
}

public class StringDeserializer: ResponseDeserializer {
    
    let stringEncoding: String.Encoding
    public var acceptContentTypes: Set<String> = ["text/plain"]
    public static var `default`: StringDeserializer {
        return StringDeserializer()
    }
    
    public init(_ encoding: String.Encoding = .utf8) {
        stringEncoding = encoding
    }
    
    public func decode(_ data: Any?) throws -> Any? {
        if let data = data as? Data {
            return String.init(data: data, encoding: stringEncoding)
        } else {
            return nil
        }
    }
}

public class DataDeserializer: ResponseDeserializer {
    public var acceptContentTypes: Set<String> = ["*/*"]
    public static var `default`: DataDeserializer {
        return DataDeserializer()
    }
    
    public func decode(_ data: Any?) throws -> Any? {
        return data
    }
}
