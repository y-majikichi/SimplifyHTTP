//
//  DownloadTask.swift
//  HttpMessenger
//
//  Created by Yuto on 2021/01/06.
//

import Foundation

public class DownloadTask: NSObject {
    let downloadTask: URLSessionDownloadTask
    public let saveURL: URL
    public var writingOptions: Data.WritingOptions
    var resumeData: Data?
    
    init(_ downloadTask: URLSessionDownloadTask , saveURL: URL, options: Data.WritingOptions = []) {
        self.downloadTask = downloadTask
        self.saveURL = saveURL
        self.writingOptions = options
    }
    
    public func cancel(_ asResumeDataHandler: @escaping (_ data: Data?) -> Void) {
        downloadTask.cancel { [weak self, asResumeDataHandler] (data) in
            self?.resumeData = data
            asResumeDataHandler(data)
        }
    }
}

