//
//  HttpMessengerLogger.swift
//  HttpMessenger
//
//  Created by Yuto on 2020/12/21.
//

import Foundation

public enum LogLevel: Int {
    case none = 0
    case verbose = 1
    case debug = 2
    case info = 3
    case warning = 4
    case error = 5
}

public class LogDetail {
    let logLevel: LogLevel
    let dateFormatter: DateFormatter
    let date: Bool
    let level: Bool
    let fileInfo: Bool
    let funcNmae: Bool
    
    public init(_ logLevel: LogLevel = .none, dateFormatter: DateFormatter? = nil, date: Bool = false, level: Bool = false, fileInfo: Bool = false, funcNmae: Bool = false) {
        self.logLevel = logLevel
        if let dateFormat = dateFormatter {
            self.dateFormatter = dateFormat
        } else {
            self.dateFormatter = DateFormatter()
            self.dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSSSSSZ"
            self.dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        }
        self.date = date
        self.level = level
        self.fileInfo = fileInfo
        self.funcNmae = funcNmae
    }
}

open class HttpMessengerLogger {
    var queue: DispatchQueue
    var detail: LogDetail
    
    public init(_ detail: LogDetail = LogDetail(), queue: DispatchQueue = DispatchQueue(label: "basicnetworking.logger.default")) {
        self.detail = detail
        self.queue = queue
    }
    
    func format(_ logLevel: LogLevel = .none, functionName: StaticString = #function, fileName: StaticString = #file, lineNumber: Int = #line, closure: @escaping () -> Any?) -> String? {
        guard let closureResult = closure() else { return nil }
        
        var log = ""
        if detail.date {
            log += "\(detail.dateFormatter.string(from: Date())) "
        }
        
        if detail.level {
            var defs = ""
            switch logLevel {
            case .error:
                defs = "E"
            case .verbose:
                defs = "V"
            case .warning:
                defs = "W"
            case .info:
                defs = "I"
            case .debug:
                fallthrough
            default:
                defs = "D"
            }
            log += "[\(defs)] "
        }
        
        if detail.fileInfo {
            let name = ("\(fileName)" as NSString).lastPathComponent
            log += "[\(name):\(lineNumber)] "
        }
        
        if detail.funcNmae {
            log += "[\(functionName)] "
        }
        return "\(log)> " + String(describing: closureResult)
    }
    
    open func output(_ logLevel: LogLevel = .none, functionName: StaticString = #function, fileName: StaticString = #file, lineNumber: Int = #line, closure: @escaping () -> Any?) {
        if detail.logLevel == .none || detail.logLevel.rawValue >= logLevel.rawValue {
            return
        }
        if let printStr = format(logLevel, functionName: functionName, fileName: fileName, lineNumber: lineNumber, closure: closure) {
            queue.sync {
                output(printStr)
            }
        }
    }
    
    func output(_ formated: String) {}
    
    func v(_ closure: @autoclosure @escaping () -> Any?, functionName: StaticString = #function, fileName: StaticString = #file, lineNumber: Int = #line) {
        output(.verbose, functionName: functionName, fileName: fileName, lineNumber: lineNumber, closure: closure)
    }
    
    func d(_ closure: @autoclosure @escaping () -> Any?, functionName: StaticString = #function, fileName: StaticString = #file, lineNumber: Int = #line) {
        output(.debug, functionName: functionName, fileName: fileName, lineNumber: lineNumber, closure: closure)
    }
    
    func i(_ closure: @autoclosure @escaping () -> Any?, functionName: StaticString = #function, fileName: StaticString = #file, lineNumber: Int = #line) {
        output(.info, functionName: functionName, fileName: fileName, lineNumber: lineNumber, closure: closure)
    }
    
    func w(_ closure: @autoclosure @escaping () -> Any?, functionName: StaticString = #function, fileName: StaticString = #file, lineNumber: Int = #line) {
        output(.warning, functionName: functionName, fileName: fileName, lineNumber: lineNumber, closure: closure)
    }
    
    func e(_ closure: @autoclosure @escaping () -> Any?, functionName: StaticString = #function, fileName: StaticString = #file, lineNumber: Int = #line) {
        output(.error, functionName: functionName, fileName: fileName, lineNumber: lineNumber, closure: closure)
    }
}
