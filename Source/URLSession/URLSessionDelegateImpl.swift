//
//  URLSessionDelegateImpl.swift
//  HttpMessenger
//
//  Created by Yuto on 2020/12/25.
//

import Foundation

class URLSessionDelegateImpl: NSObject {
    
    typealias RequestProgress = (_ task: URLSessionTask?, _ didSendBytesSent: Int64, _ totalBytesToSend: Int64, _ totalBytesExpectedToSend: Int64) -> Void
    typealias ResponseProgress = (_ task: URLSessionTask?, _ didReceiveBytes: Int64, _ totalBytesReceived: Int64, _ totalBytesReceiveExpected: Int64) -> Void
    typealias ResponseIntercepter = (_ data: Data?, _ task: URLSessionTask, _ urlResponse: URLResponse?, _ error: Error?) -> Error?
    typealias Completion = (_ task: URLSessionTask, _ urlResponse: URLResponse?, _ data: Data?, _ error: HttpMessengerError?) -> Void
    
    var data: [URLSessionTask : Data] = [:]
    weak var trustManagerDelegate: TrustManagerDelegate? = nil
    
    private var blocks: [URLSessionTask : (intercepter: ResponseIntercepter?,
                                           requestProgress: RequestProgress?,
                                           responseProgress: ResponseProgress?,
                                           completion: Completion?)]
    
    init(_ trustManagerDelegate: TrustManagerDelegate? = nil) {
        self.blocks = [:]
        self.trustManagerDelegate = trustManagerDelegate
    }
    
    deinit {
        self.blocks.removeAll()
        data.removeAll()
    }
    
    func register(_ task: URLSessionTask,
                  intercepter: ResponseIntercepter? = nil,
                  requestProgress: RequestProgress? = nil,
                  responseProgress: ResponseProgress? = nil,
                  completion: Completion? = nil) {
        blocks.updateValue((intercepter: intercepter,
                            requestProgress: requestProgress,
                            responseProgress: responseProgress,
                            completion: completion),
                           forKey: task)
    }
    
    func remove(_ task: URLSessionTask) {
        blocks.removeValue(forKey: task)
    }
    
    func executeIntercepter(_ task: URLSessionTask, data: Data?, _ urlResponse: URLResponse?, _ error: HttpMessengerError?) -> Error? {
        if let inter = blocks[task]?.intercepter {
            return inter(data, task, urlResponse, error)
        } else {
            return nil
        }
    }
    
    func executeRequestProgress(_ task: URLSessionTask, didSendBytesSent: Int64, totalBytesToSend: Int64, totalBytesExpectedToSend: Int64) {
        blocks[task]?.requestProgress?(task, didSendBytesSent, totalBytesToSend, totalBytesExpectedToSend)
    }
    
    func executeResponseProgress(_ task: URLSessionTask,
                                 didReceiveBytes: Int64,
                                 totalBytesReceived: Int64,
                                 totalBytesReceiveExpected: Int64) {
        blocks[task]?.responseProgress?(task, didReceiveBytes, totalBytesReceived, totalBytesReceiveExpected)
    }
    
    func executeCompletion(_ task: URLSessionTask, urlResponse: URLResponse?, data: Data?, error: HttpMessengerError?) {
        blocks[task]?.completion?(task, urlResponse, data, error)
    }
}

extension URLSessionDelegateImpl: URLSessionDelegate {

    @available(macOS 10.9, *)
    func urlSession(_ session: URLSession,
                    didBecomeInvalidWithError error: Error?) {
        HttpMessengerSession.logger?.d("a")
    }

    
    @available(macOS 10.9, *)
    func urlSession(_ session: URLSession,
                    didReceive challenge: URLAuthenticationChallenge,
                    completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        HttpMessengerSession.logger?.d("a")
        if let manager = trustManagerDelegate {
            manager.trustManager(session, didReceive: challenge, completionHandler: completionHandler)
        } else {
            completionHandler(.performDefaultHandling, challenge.proposedCredential)
        }
    }
}

extension URLSessionDelegateImpl: URLSessionTaskDelegate {
    
    @available(macOS 10.13, iOS 11.0, *)
    func urlSession(_ session: URLSession,
                    task: URLSessionTask,
                    willBeginDelayedRequest request: URLRequest,
                    completionHandler: @escaping (URLSession.DelayedRequestDisposition, URLRequest?) -> Void) {
        HttpMessengerSession.logger?.d("a")
        completionHandler(.continueLoading, request)
    }

    
    @available(macOS 10.13, iOS 11.0, *)
    func urlSession(_ session: URLSession,
                    taskIsWaitingForConnectivity task: URLSessionTask) {
        HttpMessengerSession.logger?.d("a")
    }

    
    @available(macOS 10.9, *)
    func urlSession(_ session: URLSession,
                    task: URLSessionTask,
                    willPerformHTTPRedirection response: HTTPURLResponse,
                    newRequest request: URLRequest,
                    completionHandler: @escaping (URLRequest?) -> Void) {
        HttpMessengerSession.logger?.d("a")
        completionHandler(request)
    }

    
    @available(macOS 10.9, *)
    func urlSession(_ session: URLSession,
                    task: URLSessionTask,
                    didReceive challenge: URLAuthenticationChallenge,
                    completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        HttpMessengerSession.logger?.d("a")
        if let manager = trustManagerDelegate {
            manager.trustManager(session, task: task, didReceive: challenge, completionHandler: completionHandler)
        } else {
            completionHandler(.performDefaultHandling, challenge.proposedCredential)
        }
    }

    
    @available(macOS 10.9, *)
    func urlSession(_ session: URLSession,
                    task: URLSessionTask,
                    needNewBodyStream completionHandler: @escaping (InputStream?) -> Void) {
        HttpMessengerSession.logger?.d("a")
        // TODO:
        completionHandler(nil)
    }

    
    @available(macOS 10.9, *)
    func urlSession(_ session: URLSession,
                    task: URLSessionTask,
                    didSendBodyData bytesSent: Int64,
                    totalBytesSent: Int64,
                    totalBytesExpectedToSend: Int64) {
        HttpMessengerSession.logger?.d("a")
        executeRequestProgress(task,
                               didSendBytesSent: bytesSent,
                               totalBytesToSend: totalBytesSent,
                               totalBytesExpectedToSend: totalBytesExpectedToSend)
    }

    
    @available(macOS 10.12, *)
    func urlSession(_ session: URLSession,
                    task: URLSessionTask,
                    didFinishCollecting metrics: URLSessionTaskMetrics) {
        HttpMessengerSession.logger?.d("a")
    }

    
    @available(macOS 10.9, *)
    func urlSession(_ session: URLSession,
                    task: URLSessionTask,
                    didCompleteWithError error: Error?) {
        HttpMessengerSession.logger?.d("a")
        // 引っ張る
        let data = self.data[task]
        // 消す
        self.data.removeValue(forKey: task)
        // intercept
        let interceptResult = executeIntercepter(task, data: data, task.response, (error != nil ? .networkingError(from: error!) : nil))
        // 丁寧に
        var retError: HttpMessengerError? = nil
        if let inter = interceptResult as? HttpMessengerError {
            retError = inter
        } else if let inter = interceptResult {
            retError = .networkingError(from: inter)
        }
        executeCompletion(task,
                          urlResponse: task.response,
                          data: data,
                          error: retError)
    }
}

extension URLSessionDelegateImpl: URLSessionDataDelegate {
    
    @available(macOS 10.9, *)
    func urlSession(_ session: URLSession,
                    dataTask: URLSessionDataTask,
                    didReceive response: URLResponse,
                    completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        HttpMessengerSession.logger?.d("a")
        completionHandler(.allow)
    }

    
    @available(macOS 10.9, *)
    func urlSession(_ session: URLSession,
                    dataTask: URLSessionDataTask,
                    didBecome downloadTask: URLSessionDownloadTask) {
        HttpMessengerSession.logger?.d("a")
    }

    
    @available(macOS 10.11, *)
    func urlSession(_ session: URLSession,
                    dataTask: URLSessionDataTask,
                    didBecome streamTask: URLSessionStreamTask) {
        HttpMessengerSession.logger?.d("a")
    }

    
    @available(macOS 10.9, *)
    func urlSession(_ session: URLSession,
                    dataTask: URLSessionDataTask,
                    didReceive data: Data) {
        HttpMessengerSession.logger?.d("a")
        if self.data[dataTask] != nil {
            self.data[dataTask]?.append(data)
        } else {
            self.data.updateValue(data, forKey: dataTask)
        }
        if let response = dataTask.response {
            executeResponseProgress(dataTask,
                                    didReceiveBytes: Int64(data.count),
                                    totalBytesReceived: Int64(self.data[dataTask]!.count),
                                    totalBytesReceiveExpected: response.expectedContentLength)
        }
    }

    
    @available(macOS 10.9, *)
    func urlSession(_ session: URLSession,
                    dataTask: URLSessionDataTask,
                    willCacheResponse proposedResponse: CachedURLResponse,
                    completionHandler: @escaping (CachedURLResponse?) -> Void) {
        HttpMessengerSession.logger?.d("a")
        completionHandler(proposedResponse)
    }
}

extension URLSessionDelegateImpl: URLSessionDownloadDelegate {

    
    @available(macOS 10.9, *)
    func urlSession(_ session: URLSession,
                    downloadTask: URLSessionDownloadTask,
                    didFinishDownloadingTo location: URL) {
        HttpMessengerSession.logger?.d("a")
    }

    
    @available(macOS 10.9, *)
    func urlSession(_ session: URLSession,
                    downloadTask: URLSessionDownloadTask,
                    didWriteData bytesWritten: Int64,
                    totalBytesWritten: Int64,
                    totalBytesExpectedToWrite: Int64) {
        HttpMessengerSession.logger?.d("a")
    }

    
    @available(macOS 10.9, *)
    func urlSession(_ session: URLSession,
                    downloadTask: URLSessionDownloadTask,
                    didResumeAtOffset fileOffset: Int64,
                    expectedTotalBytes: Int64) {
        HttpMessengerSession.logger?.d("a")
    }
}

extension URLSessionDelegateImpl: URLSessionStreamDelegate {

    
    @available(macOS 10.11, *)
    func urlSession(_ session: URLSession,
                    readClosedFor streamTask: URLSessionStreamTask) {
        HttpMessengerSession.logger?.d("a")
    }

    
    @available(macOS 10.11, *)
    func urlSession(_ session: URLSession,
                    writeClosedFor streamTask: URLSessionStreamTask) {
        HttpMessengerSession.logger?.d("a")
    }

    
    @available(macOS 10.11, *)
    func urlSession(_ session: URLSession,
                    betterRouteDiscoveredFor streamTask: URLSessionStreamTask) {
        HttpMessengerSession.logger?.d("a")
    }

    
    @available(macOS 10.11, *)
    func urlSession(_ session: URLSession,
                    streamTask: URLSessionStreamTask,
                    didBecome inputStream: InputStream,
                    outputStream: OutputStream) {
        HttpMessengerSession.logger?.d("a")
    }
}

@available(macOS 10.15, iOS 13.0, *)
extension URLSessionDelegateImpl: URLSessionWebSocketDelegate {

    
    @available(iOS 13.0, *)
    func urlSession(_ session: URLSession,
                    webSocketTask: URLSessionWebSocketTask,
                    didOpenWithProtocol protocol: String?) {
        HttpMessengerSession.logger?.d("a")
    }

    
    func urlSession(_ session: URLSession,
                    webSocketTask: URLSessionWebSocketTask,
                    didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        HttpMessengerSession.logger?.d("a")
    }
}

