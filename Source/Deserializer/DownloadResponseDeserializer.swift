//
//  DownloadResponseDeserializer.swift
//  HttpMessenger
//
//  Created by Yuto on 2021/01/05.
//

import Foundation

public protocol DownloadResponseDeserializer: ResponseDeserializer {
    var saveURL: URL { get }
    var writingOptions: Data.WritingOptions { get }
    func save(_ contentsOfFile: URL) throws -> Bool
}

public class DataDownloadResponseDeserializer: DownloadResponseDeserializer {
    public let saveURL: URL
    public var writingOptions: Data.WritingOptions
    public var acceptContentTypes: Set<String> = ["*/*"]
    
    public init(_ saveURL: URL, options: Data.WritingOptions = []) {
        self.saveURL = saveURL
        self.writingOptions = options
    }
    
    public func decode(_ data: Any?) throws -> Any? {
        if let data = data as? URL {
            return data
        } else {
            throw HttpMessengerError.decoderError
        }
    }
    
    public func save(_ contentsOfFile: URL) throws -> Bool {
        var saved = false
        try Data.init(contentsOf: contentsOfFile).write(to: saveURL, options: writingOptions)
        saved = true
        return saved
    }
}
