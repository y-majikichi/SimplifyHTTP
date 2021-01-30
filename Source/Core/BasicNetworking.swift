//
//  BasicNetworking.swift
//  HttpMessenger
//
//  Created by Yuto on 2020/12/17.
//

import Foundation

class HttpMessengerSession: NSObject {
    
    private (set) var urlSession: URLSession
    static var logger: HttpMessengerLogger? = nil
    private var defaultHeaders: [HTTPHeader]
    private var sessionDelegate: URLSessionDelegateImpl?
    
    private static let kDelegateMode = true
    
    typealias RequestProgress = (_ networking: HttpMessengerSession, _ urlRequest: URLRequest?, _ didSendBytesSent: Int64, _ totalBytesExpectedToSend: Int64, _ totalBytesExpectedToSend: Int64) -> Void
    typealias ResponseProgress = (_ networking: HttpMessengerSession, _ urlRequest: URLRequest?, _ didReceiveBytes: Int64, _ totalBytesReceived: Int64, _ totalBytesReceiveExpected: Int64) -> Void
    typealias ResponseIntercepter = (_ networking: HttpMessengerSession, _ data: Data?, _ urlRequest: URLRequest?, _ urlResponse: URLResponse?, _ error: Error?) -> Error?
    typealias Success = (_ networking: HttpMessengerSession, _ urlRequest: URLRequest, _ urlResponse: URLResponse, _ data: Any?) -> Void
    typealias Failure = (_ networking: HttpMessengerSession, _ urlRequest: URLRequest, _ urlResponse: URLResponse?, _ error: HttpMessengerError) -> Void
    
    typealias InnerCompletion = (_ urlRequest: URLRequest, _ data: Data?, _ urlResponse: URLResponse?, _ error: HttpMessengerError?) -> Void
    
    var requestArrays:[(request: URLRequest, task: URLSessionTask)] = []
    
    private static var sharedInstance: HttpMessengerSession = HttpMessengerSession.makeShared()
    
    private init(_ urlSession:URLSession, sessionDelegate: URLSessionDelegateImpl? = nil) {
        self.urlSession = urlSession
        self.sessionDelegate = sessionDelegate
        defaultHeaders = []
    }
    
    deinit {
        self.sessionDelegate = nil
        self.urlSession.invalidateAndCancel()
        defaultHeaders.removeAll()
    }
    
    private static func makeShared() -> HttpMessengerSession {
        if kDelegateMode {
            return networking()
        } else {
            return networking(URLSession.shared)
        }
    }
    
    static func networking(_ urlSessionConfig:URLSessionConfiguration = .default, delegateQueue: OperationQueue? = nil) -> HttpMessengerSession {
        let delegate = URLSessionDelegateImpl()
        let session: URLSession = URLSession(configuration: urlSessionConfig, delegate: (HttpMessengerSession.kDelegateMode ? delegate : nil), delegateQueue: delegateQueue)
        return networking(session, sessionDelegate: delegate)
    }
    
    static func shared() -> HttpMessengerSession {
        return sharedInstance
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
    
    private func intercept(_ intercepter: ResponseIntercepter?, urlRequest: URLRequest, data: Data?, urlResponse: URLResponse?, error: Error?) -> Error? {
        HttpMessengerSession.logger?.d("intercept")
        // arrayから削除
        if let target = requestArrays.firstIndex(where: { $0.request == urlRequest }) {
            requestArrays.remove(at: target)
        }
        
        // arrayから削除
        if let inter = intercepter {
            HttpMessengerSession.logger?.d("intercepter")
            return inter(self, data, urlRequest, urlResponse, error)
        } else {
            return nil
        }
    }
    
    private func analysisResponse(urlRequest: URLRequest, responseDeserializer: ResponseDeserializer, data: Data?, urlResponse:URLResponse?, error:Error?, success: Success?, failure: Failure?) {
        if let error = error {
            HttpMessengerSession.logger?.e("detect error: \(error.localizedDescription) \n")
            failure?(self, urlRequest, urlResponse, .networkingError(from: error))
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
                        HttpMessengerSession.logger?.d("[RESPONSE][DECODED] Body(as String(describing)): " + String(describing: decoded) + " Bytes")
                        success?(self, urlRequest, urlResponse, decoded)
                    } catch let serializerError {
                        HttpMessengerSession.logger?.e("can't decode response")
                        failure?(self, urlRequest, urlResponse, .failedSerialize(from: serializerError))
                    }
                } else {
                    // no data
                    HttpMessengerSession.logger?.d("[RESPONSE][DECODED] No Body")
                    success?(self, urlRequest, urlResponse, decoded)
                }
            } else {
                // レスポンスのステータスコードが200でない場合などはサーバサイドエラー
                HttpMessengerSession.logger?.e("can't acceptable status code: \(urlResponse.statusCodeAsHttpStatus())\n")
                failure?(self, urlRequest, urlResponse, .statusError(status: urlResponse.statusCodeAsHttpStatus()))
            }
        } else {
            HttpMessengerSession.logger?.e("can't detect response")
            failure?(self, urlRequest, urlResponse, .responseError)
        }
    }
    
    private func requestFinish () {
        
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

/// DataTask
extension HttpMessengerSession {


    static func request(_ url:URL,
                        methodType: HTTPMethodType,
                        requestSerializer: RequestSerializer = JSONSerializer(),
                        responseDeserializer: ResponseDeserializer = JSONDeserializer(),
                        cachePolicy: URLRequest.CachePolicy = .useProtocolCachePolicy,
                        timeoutInterval: TimeInterval = TimeInterval(10),
                        headers:[String : String]? = nil,
                        parameters:Any? = nil,
                        requestProgress: RequestProgress? = nil,
                        responseProgress: ResponseProgress? = nil,
                        intercepter: ResponseIntercepter? = nil,
                        success: Success? = nil,
                        failure: Failure? = nil) -> URLSessionDataTask {
        let networking: HttpMessengerSession = HttpMessengerSession.shared()
        return networking.request(url,
                                  methodType: methodType,
                                  requestSerializer: requestSerializer,
                                  responseDeserializer: responseDeserializer,
                                  cachePolicy: cachePolicy,
                                  timeoutInterval: timeoutInterval,
                                  headers: headers,
                                  parameters: parameters,
                                  requestProgress: requestProgress,
                                  responseProgress: responseProgress,
                                  intercepter: intercepter,
                                  success: success,
                                  failure: failure)
    }
    
    func request(_ url:URL,
                 methodType: HTTPMethodType,
                 requestSerializer: RequestSerializer = JSONSerializer(),
                 responseDeserializer: ResponseDeserializer = JSONDeserializer(),
                 cachePolicy: URLRequest.CachePolicy = .useProtocolCachePolicy,
                 timeoutInterval: TimeInterval = TimeInterval(10),
                 headers:[String : String]? = nil,
                 parameters:Any? = nil,
                 requestProgress: RequestProgress? = nil,
                 responseProgress: ResponseProgress? = nil,
                 intercepter: ResponseIntercepter? = nil,
                 success: Success? = nil,
                 failure: Failure? = nil) -> URLSessionDataTask {
        let task = prepareDataTask(url,
                                   methodType: methodType,
                                   requestSerializer: requestSerializer,
                                   cachePolicy: cachePolicy,
                                   timeoutInterval: timeoutInterval,
                                   headers: headers,
                                   parameters: parameters,
                                   requestProgress: requestProgress,
                                   responseProgress: responseProgress,
                                   intercepter: intercepter) { [weak self] (request, data, response, error) in
            self?.analysisResponse(urlRequest: request,
                                   responseDeserializer: responseDeserializer,
                                   data: data,
                                   urlResponse: response,
                                   error: error,
                                   success: success,
                                   failure: failure)
        }
        task.resume()
        return task
    }
    
    private func prepareDataTask(_ url:URL,
                                 methodType: HTTPMethodType,
                                 requestSerializer: RequestSerializer,
                                 cachePolicy: URLRequest.CachePolicy,
                                 timeoutInterval: TimeInterval,
                                 headers:[String : String]?,
                                 parameters:Any?,
                                 requestProgress: RequestProgress? = nil,
                                 responseProgress: ResponseProgress? = nil,
                                 intercepter: ResponseIntercepter? = nil,
                                 completionHandler: @escaping InnerCompletion) -> URLSessionDataTask {
        HttpMessengerSession.logger?.d("prepareDataTask")
        let urlRequest = URLRequestUtils.makeRequest(url,
                                                     cachePolicy: cachePolicy,
                                                     timeoutInterval: timeoutInterval,
                                                     methodType: methodType,
                                                     requestSerializer: requestSerializer,
                                                     defaultHeaders: defaultHeaders,
                                                     headers: headers,
                                                     parameters: parameters)
        urlRequest.printUrls(logger: HttpMessengerSession.logger)
        urlRequest.printHeaders(logger: HttpMessengerSession.logger)
        urlRequest.printBody(logger: HttpMessengerSession.logger)
        if HttpMessengerSession.kDelegateMode {
            let sessionTask = urlSession.dataTask(with: urlRequest)
            self.sessionDelegate?.register(sessionTask,
                                           intercepter: { [weak self] (data, task, response, error) -> Error? in
                                            if let weakSelf = self {
                                                return weakSelf.intercept(intercepter,
                                                                          urlRequest: urlRequest,
                                                                          data: data,
                                                                          urlResponse: response,
                                                                          error: error)
                                            } else {
                                                return nil
                                            }
                                           },
                                           requestProgress: { [weak self] (task, sent, totalSend, total) in
                                            if let weakSelf = self {
                                                requestProgress?(weakSelf, urlRequest, sent, totalSend, total)
                                            }
                                           },
                                           responseProgress: { [weak self] (task, rec, totalRec, exp) in
                                            if let weakSelf = self {
                                                responseProgress?(weakSelf, urlRequest, rec, totalRec, exp)
                                            }
                                           },
                                           completion: { (task, response, data, error) in
                                            completionHandler(urlRequest, data, response, error)
                                           })
            requestArrays.append((urlRequest, sessionTask))
            return sessionTask
        } else {
            let sessionTask = urlSession.dataTask(with: urlRequest) { [weak self] (data, response, error) in
                if let response = response {
                    response.printUrls(logger: HttpMessengerSession.logger)
                    response.printHeaders(logger: HttpMessengerSession.logger)
                } else {
                    HttpMessengerSession.logger?.d("[RESPONSE] Not Detect Response")
                }
                if let data = data {
                    HttpMessengerSession.logger?.d("[RESPONSE] Body(as Data): \(data.count) Bytes")
                } else {
                    HttpMessengerSession.logger?.d("[RESPONSE] Not Detect Body")
                }
                if let error = error {
                    HttpMessengerSession.logger?.e("[RESPONSE] Error: " + error.localizedDescription)
                }
                let interceptResult: Error? = self?.intercept(intercepter, urlRequest: urlRequest, data: data, urlResponse: response, error: error) ?? nil
                var retError: HttpMessengerError? = nil
                if let inter = interceptResult as? HttpMessengerError {
                    retError = inter
                } else if let inter = interceptResult {
                    retError = .networkingError(from: inter)
                }
                completionHandler(urlRequest, data, response, retError)
            }
            requestArrays.append((urlRequest, sessionTask))
            return sessionTask
        }
    }
}

/// Download
extension HttpMessengerSession {
    
    func download(_ url:URL,
                 methodType: HTTPMethodType,
                 requestSerializer: RequestSerializer = JSONSerializer(),
                 responseDeserializer: ResponseDeserializer = JSONDeserializer(),
                 cachePolicy: URLRequest.CachePolicy = .useProtocolCachePolicy,
                 timeoutInterval: TimeInterval = TimeInterval(10),
                 headers:[String : String]? = nil,
                 requestProgress: RequestProgress? = nil,
                 responseProgress: ResponseProgress? = nil,
                 intercepter: ResponseIntercepter? = nil,
                 success: Success? = nil,
                 failure: Failure? = nil) -> URLSessionDownloadTask {
        let task = prepareDownloadTask(url,
                                       methodType: methodType,
                                       requestSerializer: requestSerializer,
                                       cachePolicy: cachePolicy,
                                       timeoutInterval: timeoutInterval,
                                       headers: headers,
                                       requestProgress: requestProgress,
                                       responseProgress: responseProgress,
                                       intercepter: intercepter) { [weak self] (request, data, response, error) in
            self?.analysisResponse(urlRequest: request,
                                   responseDeserializer: responseDeserializer,
                                   data: data,
                                   urlResponse: response,
                                   error: error,
                                   success: success,
                                   failure: failure)
        }
        task.resume()
        return task
    }
    
    private func prepareDownloadTask(_ url:URL,
                                 methodType: HTTPMethodType,
                                 requestSerializer: RequestSerializer,
                                 cachePolicy: URLRequest.CachePolicy,
                                 timeoutInterval: TimeInterval,
                                 headers:[String : String]?,
                                 requestProgress: RequestProgress? = nil,
                                 responseProgress: ResponseProgress? = nil,
                                 intercepter: ResponseIntercepter? = nil,
                                 completionHandler: @escaping InnerCompletion) -> URLSessionDownloadTask {
        HttpMessengerSession.logger?.d("prepareDownloadTask")
        let urlRequest = URLRequestUtils.makeDownloadRequest(url,
                                                             cachePolicy: cachePolicy,
                                                             timeoutInterval: timeoutInterval,
                                                             methodType: methodType,
                                                             requestSerializer: requestSerializer,
                                                             defaultHeaders: defaultHeaders,
                                                             headers: headers)
        let task = urlSession.downloadTask(with: urlRequest) { [weak self] (url, response, error) in
            let interceptResult: Error? = self?.intercept(intercepter, urlRequest: urlRequest, data: nil, urlResponse: response, error: error) ?? nil
            var retError: HttpMessengerError? = nil
            if let inter = interceptResult as? HttpMessengerError {
                retError = inter
            } else if let inter = interceptResult {
                retError = .networkingError(from: inter)
            }
            completionHandler(urlRequest, nil, response, retError)
        }
        requestArrays.append((urlRequest, task))
        return task
    }
}

/// Upload
extension HttpMessengerSession {
    
    func upload(_ url:URL,
                 methodType: HTTPMethodType,
                 requestSerializer: RequestSerializer = JSONSerializer(),
                 responseDeserializer: ResponseDeserializer = JSONDeserializer(),
                 cachePolicy: URLRequest.CachePolicy = .useProtocolCachePolicy,
                 timeoutInterval: TimeInterval = TimeInterval(10),
                 headers:[String : String]? = nil,
                 data: Data?,
                 requestProgress: RequestProgress? = nil,
                 responseProgress: ResponseProgress? = nil,
                 intercepter: ResponseIntercepter? = nil,
                 success: Success? = nil,
                 failure: Failure? = nil) -> URLSessionUploadTask {
        let task = prepareUploadTask(url,
                                     methodType: methodType,
                                     cachePolicy: cachePolicy,
                                     timeoutInterval: timeoutInterval,
                                     headers: headers,
                                     data: data,
                                     requestProgress: requestProgress,
                                     responseProgress: responseProgress,
                                     intercepter: intercepter) { [weak self] (request, data, response, error) in
            self?.analysisResponse(urlRequest: request,
                                   responseDeserializer: responseDeserializer,
                                   data: data,
                                   urlResponse: response,
                                   error: error,
                                   success: success,
                                   failure: failure)
        }
        task.resume()
        return task
    }
    
    private func prepareUploadTask(_ url:URL,
                                 methodType: HTTPMethodType,
                                 cachePolicy: URLRequest.CachePolicy,
                                 timeoutInterval: TimeInterval,
                                 headers:[String : String]?,
                                 data: Data?,
                                 requestProgress: RequestProgress? = nil,
                                 responseProgress: ResponseProgress? = nil,
                                 intercepter: ResponseIntercepter? = nil,
                                 completionHandler: @escaping InnerCompletion) -> URLSessionUploadTask {
        HttpMessengerSession.logger?.d("prepareUploadTask")
        let urlRequest = URLRequestUtils.makeUploadRequest(url,
                                                           cachePolicy: cachePolicy,
                                                           timeoutInterval: timeoutInterval,
                                                           methodType: methodType,
                                                           defaultHeaders: defaultHeaders,
                                                           headers: headers)
        let task = urlSession.uploadTask(with: urlRequest, from: data) { [weak self] (data, response, error) in
            let interceptResult: Error? = self?.intercept(intercepter, urlRequest: urlRequest, data: data, urlResponse: response, error: error) ?? nil
            var retError: HttpMessengerError? = nil
            if let inter = interceptResult as? HttpMessengerError {
                retError = inter
            } else if let inter = interceptResult {
                retError = .networkingError(from: inter)
            }
            completionHandler(urlRequest, data, response, retError)
        }
        requestArrays.append((urlRequest, task))
        return task
    }
}
