//
//  BasicNetworkingActivityLogger.swift
//  HttpMessenger
//
//  Created by Yuto on 2020/12/21.
//

import Foundation

public class HttpMessengerLoggerActivityLogger: HttpMessengerLogger {
    
    public init(_ logLevel: LogLevel = .debug) {
        let logDetail = LogDetail(logLevel, dateFormatter: nil, date: true, level: true, fileInfo: true, funcNmae: true)
        super.init(logDetail)
    }
    
    override func output(_ formated: String) {
        print(formated)
    }
}

public class SystemNetworkingActivityLogger: HttpMessengerLogger {
    
    public init(_ logLevel: LogLevel = .debug) {
        let logDetail = LogDetail(logLevel, dateFormatter: nil, date: false, level: true, fileInfo: true, funcNmae: true)
        super.init(logDetail)
    }
    
    override func output(_ formated: String) {
        NSLog(formated)
    }
}
