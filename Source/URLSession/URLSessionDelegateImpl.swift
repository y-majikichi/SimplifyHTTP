//
//  URLSessionDelegateImpl.swift
//  HttpMessenger
//
//  Created by Yuto on 2020/12/25.
//

import Foundation

class URLSessionDelegateImpl: NSObject {
    
    typealias RequestProgress     = (_ task: URLSessionTask, _ didSendBytesSent: Int64, _ totalBytesToSend: Int64, _ totalBytesExpectedToSend: Int64) -> Void
    typealias ResponseProgress    = (_ task: URLSessionTask, _ didReceiveBytes: Int64, _ totalBytesReceived: Int64, _ totalBytesReceiveExpected: Int64) -> Void
    typealias ResponseIntercepter = (_ data: Any?, _ task: URLSessionTask, _ urlResponse: URLResponse?, _ error: Error?) -> Error?
    typealias Completion = (_ task: URLSessionTask, _ urlResponse: URLResponse?, _ data: Any?, _ error: HttpMessengerError?) -> Void
    
    var dataTaskData: [URLSessionTask : Any?] = [:]
    
    weak var trustManagerDelegate: TrustManagerDelegate? = nil
    
    private var blocks: [URLSessionTask : (downloadDeserializer: DownloadResponseDeserializer?,
                                           intercepter: ResponseIntercepter?,
                                           requestProgress: RequestProgress?,
                                           responseProgress: ResponseProgress?,
                                           completion: Completion?)]
    
    init(_ trustManagerDelegate: TrustManagerDelegate? = nil) {
        self.blocks = [:]
        self.trustManagerDelegate = trustManagerDelegate
    }
    
    deinit {
        self.blocks.removeAll()
        dataTaskData.removeAll()
    }
    
    func register(_ task: URLSessionTask,
                  downloadDeserializer: DownloadResponseDeserializer? = nil,
                  intercepter: ResponseIntercepter? = nil,
                  requestProgress: RequestProgress? = nil,
                  responseProgress: ResponseProgress? = nil,
                  completion: Completion? = nil) {
        blocks.updateValue((downloadDeserializer: downloadDeserializer,
                            intercepter: intercepter,
                            requestProgress: requestProgress,
                            responseProgress: responseProgress,
                            completion: completion),
                           forKey: task)
    }
    
    func remove(_ task: URLSessionTask) {
        blocks.removeValue(forKey: task)
    }
    
    func removeAll() {
        blocks.removeAll()
    }
    
    func executeDonwloadSave(_ task: URLSessionDownloadTask, url: URL) throws -> Bool {
        if let inter = blocks[task]?.downloadDeserializer {
            return try inter.save(url)
        } else {
            return false
        }
    }
    
    func executeIntercepter(_ task: URLSessionTask, data: Any?, _ urlResponse: URLResponse?, _ error: HttpMessengerError?) -> Error? {
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
    
    func executeCompletion(_ task: URLSessionTask, urlResponse: URLResponse?, data: Any?, error: HttpMessengerError?) {
        blocks[task]?.completion?(task, urlResponse, data, error)
    }
}

extension URLSessionDelegateImpl: URLSessionDelegate {

    @available(macOS 10.9, *)
    func urlSession(_ session: URLSession,
                    didBecomeInvalidWithError error: Error?) {
        HttpMessengerSession.logger?.d("Error : " + (error?.localizedDescription ?? "Not Defined"))
    }

    
    @available(macOS 10.9, *)
    func urlSession(_ session: URLSession,
                    didReceive challenge: URLAuthenticationChallenge,
                    completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        if let manager = trustManagerDelegate {
            HttpMessengerSession.logger?.d("Respond trustManager Delegate")
            manager.trustManager(session, didReceive: challenge, completionHandler: completionHandler)
        } else {
            HttpMessengerSession.logger?.d("Default Handle")
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
        HttpMessengerSession.logger?.d("Delayed Request : " + (request.url?.absoluteString ?? "Not Defined URL"))
        completionHandler(.continueLoading, request)
    }

    
    @available(macOS 10.13, iOS 11.0, *)
    func urlSession(_ session: URLSession,
                    taskIsWaitingForConnectivity task: URLSessionTask) {
        HttpMessengerSession.logger?.d("Waiting Connectivity")
    }

    
    @available(macOS 10.9, *)
    func urlSession(_ session: URLSession,
                    task: URLSessionTask,
                    willPerformHTTPRedirection response: HTTPURLResponse,
                    newRequest request: URLRequest,
                    completionHandler: @escaping (URLRequest?) -> Void) {
        HttpMessengerSession.logger?.d("Redirect New :" + (request.url?.absoluteString ?? "Not Defined URL"))
        completionHandler(request)
    }

    
    @available(macOS 10.9, *)
    func urlSession(_ session: URLSession,
                    task: URLSessionTask,
                    didReceive challenge: URLAuthenticationChallenge,
                    completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        if let manager = trustManagerDelegate {
            HttpMessengerSession.logger?.d("Respond trustManager Delegate")
            manager.trustManager(session, task: task, didReceive: challenge, completionHandler: completionHandler)
        } else {
            HttpMessengerSession.logger?.d("Default Handle")
            completionHandler(.performDefaultHandling, challenge.proposedCredential)
        }
    }

    
    @available(macOS 10.9, *)
    func urlSession(_ session: URLSession,
                    task: URLSessionTask,
                    needNewBodyStream completionHandler: @escaping (InputStream?) -> Void) {
        HttpMessengerSession.logger?.d("New Body Stream")
        // TODO:
        completionHandler(nil)
    }

    
    @available(macOS 10.9, *)
    func urlSession(_ session: URLSession,
                    task: URLSessionTask,
                    didSendBodyData bytesSent: Int64,
                    totalBytesSent: Int64,
                    totalBytesExpectedToSend: Int64) {
        HttpMessengerSession.logger?.d("Request Progress")
        executeRequestProgress(task,
                               didSendBytesSent: bytesSent,
                               totalBytesToSend: totalBytesSent,
                               totalBytesExpectedToSend: totalBytesExpectedToSend)
    }

    
    @available(macOS 10.12, *)
    func urlSession(_ session: URLSession,
                    task: URLSessionTask,
                    didFinishCollecting metrics: URLSessionTaskMetrics) {
        HttpMessengerSession.logger?.d("Finish Collecting")
    }

    
    @available(macOS 10.9, *)
    func urlSession(_ session: URLSession,
                    task: URLSessionTask,
                    didCompleteWithError error: Error?) {
        HttpMessengerSession.logger?.d("Finish Requests")
        // 引っ張る
        // Error or URL or Data or nil
        let data = self.dataTaskData[task] ?? nil
        // 消す
        self.dataTaskData.removeValue(forKey: task)
        var submitError = error
        if error == nil, let er = data as? Error {
            submitError = er
        }
        // intercept
        let interceptResult = executeIntercepter(task, data: data, task.response, (submitError != nil ? .networkingError(from: submitError!) : nil))
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
        // Blockクリア
        self.blocks.removeValue(forKey: task)
    }
}

extension URLSessionDelegateImpl: URLSessionDataDelegate {
    
    @available(macOS 10.9, *)
    func urlSession(_ session: URLSession,
                    dataTask: URLSessionDataTask,
                    didReceive response: URLResponse,
                    completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        HttpMessengerSession.logger?.d("Response Received")
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
        let bytes: Int
        if self.dataTaskData[dataTask] != nil, var taskData = self.dataTaskData[dataTask] as? Data {
            taskData.append(data)
            self.dataTaskData.updateValue(taskData, forKey: dataTask)
            bytes = taskData.count
        } else {
            self.dataTaskData.updateValue(data, forKey: dataTask)
            bytes = data.count
        }
        if let response = dataTask.response {
            executeResponseProgress(dataTask,
                                    didReceiveBytes: Int64(data.count),
                                    totalBytesReceived: Int64(bytes),
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
        do {
            _ = try executeDonwloadSave(downloadTask, url: location)
            self.dataTaskData.updateValue(self.blocks[downloadTask]?.downloadDeserializer?.saveURL, forKey: downloadTask)
        } catch {
            self.dataTaskData.updateValue(error, forKey: downloadTask)
        }
    }

    
    @available(macOS 10.9, *)
    func urlSession(_ session: URLSession,
                    downloadTask: URLSessionDownloadTask,
                    didWriteData bytesWritten: Int64,
                    totalBytesWritten: Int64,
                    totalBytesExpectedToWrite: Int64) {
        HttpMessengerSession.logger?.d("a")
        executeResponseProgress(downloadTask,
                                didReceiveBytes: bytesWritten,
                                totalBytesReceived: totalBytesWritten,
                                totalBytesReceiveExpected: totalBytesExpectedToWrite)
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

