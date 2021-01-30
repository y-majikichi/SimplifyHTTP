//
//  HttpMessengerSession.swift
//  HttpMessenger
//
//  Created by Yuto on 2020/12/17.
//

import Foundation

public class HttpMessengerSession: NSObject {
    
    private (set) var urlSession: URLSession
    public static var logger: HttpMessengerLogger? = nil
    private (set) var defaultHeaders: HTTPHeaders
    private (set) var sessionDelegate: URLSessionDelegateImpl?
    
    static let kDelegateMode = true
    
    public typealias RequestProgress = (_ networking: HttpMessengerSession,
                                        _ urlRequest: URLRequest?,
                                        _ didSendBytesSent: Int64,
                                        _ totalBytesExpectedToSend: Int64,
                                        _ totalBytesExpectedToSend: Int64) -> Void
    public typealias ResponseProgress = (_ networking: HttpMessengerSession,
                                         _ urlRequest: URLRequest?,
                                         _ didReceiveBytes: Int64,
                                         _ totalBytesReceived: Int64,
                                         _ totalBytesReceiveExpected: Int64) -> Void
    public typealias ResponseIntercepter = (_ networking: HttpMessengerSession,
                                            _ data: Any?,
                                            _ urlRequest: URLRequest?,
                                            _ urlResponse: URLResponse?,
                                            _ error: Error?) -> Error?
    public typealias Success = (_ networking: HttpMessengerSession,
                                _ urlRequest: URLRequest,
                                _ urlResponse: URLResponse,
                                _ data: Any?) -> Void
    public typealias Failure = (_ networking: HttpMessengerSession,
                                _ urlRequest: URLRequest?,
                                _ urlResponse: URLResponse?,
                                _ error: HttpMessengerError) -> Void
    
    public typealias InnerCompletion = (_ urlRequest: URLRequest?,
                                        _ data: Any?,
                                        _ urlResponse: URLResponse?,
                                        _ error: HttpMessengerError?) -> Void
    
    var requestArrays:[(request: URLRequest, task: URLSessionTask)] = []
    
    private static var sharedInstance: HttpMessengerSession = HttpMessengerSession.makeShared()
    
    private init(_ urlSession:URLSession, sessionDelegate: URLSessionDelegateImpl? = nil) {
        self.urlSession = urlSession
        self.sessionDelegate = sessionDelegate
        defaultHeaders = HTTPHeaders([])
    }
    
    deinit {
        self.sessionDelegate = nil
        invalidate()
        defaultHeaders.removeAll()
        requestArrays.removeAll()
    }
    
    private static func makeShared() -> HttpMessengerSession {
        if kDelegateMode {
            return networking()
        } else {
            return networking(URLSession.shared)
        }
    }
    
    public static func shared() -> HttpMessengerSession {
        return sharedInstance
    }
    
    public static func networking(_ urlSessionConfig:URLSessionConfiguration = .default,
                                  delegateQueue: OperationQueue? = OperationQueue.main,
                                  trustManager: TrustManagerDelegate? = nil) -> HttpMessengerSession {
        let delegate = URLSessionDelegateImpl(trustManager)
        let session = URLSession(configuration: urlSessionConfig, delegate: (HttpMessengerSession.kDelegateMode ? delegate : nil), delegateQueue: delegateQueue)
        return networking(session, sessionDelegate: delegate)
    }
    
    private static func networking(_ urlSession:URLSession, sessionDelegate: URLSessionDelegateImpl? = nil) -> HttpMessengerSession {
        return HttpMessengerSession(urlSession, sessionDelegate: sessionDelegate)
    }
    
//    func stream(_ url:URL,
//                methodType: HTTPMethodType,
//                headers:[String : String]? = nil) -> URLSessionStreamTask {
//       let task = prepareStreamTask(url, methodType: methodType, headers: headers)
//       task.resume()
//       return task
//   }
    
//    func webSocket(_ url:URL,
//                methodType: HTTPMethodType,
//                headers:[String : String]? = nil) -> URLSessionWebSocketTask {
//       let task = prepareWebSocketTask(url, methodType: methodType, headers: headers)
//       task.resume()
//       return task
//   }
    
    func intercept(_ intercepter: ResponseIntercepter?,
                   urlRequest: URLRequest,
                   data: Any?,
                   urlResponse: URLResponse?,
                   error: Error?) -> Error? {
        HttpMessengerSession.logger?.d("intercept")
        // arrayから削除
        if let target = requestArrays.firstIndex(where: { $0.request == urlRequest }) {
            requestArrays.remove(at: target)
        }
        
        // 評価
        if let inter = intercepter {
            HttpMessengerSession.logger?.d("intercepter")
            return inter(self, data, urlRequest, urlResponse, error)
        } else {
            return error
        }
    }
    
    func analysisResponse(urlRequest: URLRequest?,
                          responseDeserializer: ResponseDeserializer,
                          data: Any?,
                          urlResponse:URLResponse?,
                          error:Error?,
                          success: Success?,
                          failure: Failure?) {
        
        urlResponse?.printUrls(logger: HttpMessengerSession.logger)
        urlResponse?.printHeaders(logger: HttpMessengerSession.logger)
        
        if urlRequest == nil {
            HttpMessengerSession.logger?.e("make request error: \(String(describing: error?.localizedDescription))")
            let noticeError: HttpMessengerError
            if error != nil {
                noticeError = (error as? HttpMessengerError) ?? .networkingError(from: error!)
            } else {
                noticeError = .unknownError
            }
            failure?(self, urlRequest, urlResponse, noticeError)
            return
        }
        
        if let error = error {
            HttpMessengerSession.logger?.e("detect error: \(error.localizedDescription) \n")
            failure?(self, urlRequest, urlResponse, (error as? HttpMessengerError) ?? .networkingError(from: error))
            return
        }

        if let urlResponse = urlResponse {
            if urlResponse.isSuccess() {
                HttpMessengerSession.logger?.d(data)
                var decoded: Any? = nil
                if let data = data {
                    // deserialize
                    do {
                        decoded = try responseDeserializer.decode(data)
                        HttpMessengerSession.logger?.d("[RESPONSE][DECODED] Body(as String(describing)): " + String(describing: decoded))
                        success?(self, urlRequest!, urlResponse, decoded)
                    } catch let serializerError {
                        HttpMessengerSession.logger?.e("can't decode response")
                        failure?(self, urlRequest, urlResponse, .failedSerialize(from: serializerError))
                    }
                } else {
                    // no data
                    HttpMessengerSession.logger?.d("[RESPONSE][DECODED] No Body")
                    success?(self, urlRequest!, urlResponse, decoded)
                }
            } else {
                // レスポンスのステータスコードが200でない場合などはサーバサイドエラー
                HttpMessengerSession.logger?.e("can't acceptable status code: \(urlResponse.statusCodeAsHttpStatus())(\(urlResponse.statusCodeAsHttpStatus().rawValue))")
                failure?(self, urlRequest, urlResponse, .statusError(status: urlResponse.statusCodeAsHttpStatus()))
            }
        } else {
            HttpMessengerSession.logger?.e("can't detect response")
            failure?(self, urlRequest, urlResponse, .responseError)
        }
    }
    
    public func invalidate () {
        HttpMessengerSession.logger?.d("Session invalidate")
        sessionDelegate?.removeAll()
        self.urlSession.invalidateAndCancel()
    }
    
//    private func prepareStreamTask(_ url:URL,
//                                 methodType: HTTPMethodType,
//                                 headers:[String : String]? = nil) -> URLSessionStreamTask {
//        // 工事中というか勉強中
//        return URLSessionStreamTask()
//    }
    
//    private func prepareWebSocketTask(_ url:URL,
//                                      methodType: HTTPMethodType,
//                                      headers:[String : String]? = nil) -> URLSessionWebSocketTask {
//        // 工事中というか勉強中
//        return URLSessionWebSocketTask()
//    }
}
