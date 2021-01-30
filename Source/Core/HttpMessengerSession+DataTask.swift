//
//  HttpMessengerSession+DataTask.swift
//  HttpMessenger
//
//  Created by Yuto on 2021/01/12.
//

import Foundation

/// DataTask
extension HttpMessengerSession {

    public static func request(_ url:URL,
                        methodType: HTTPMethodType,
                        requestSerializer: RequestSerializer = JSONSerializer(),
                        responseDeserializer: ResponseDeserializer = JSONDeserializer(),
                        headers:[String : String]? = nil,
                        parameters:Any? = nil,
                        requestProgress: RequestProgress? = nil,
                        responseProgress: ResponseProgress? = nil,
                        intercepter: ResponseIntercepter? = nil,
                        success: Success? = nil,
                        failure: Failure? = nil) {
        let networking: HttpMessengerSession = HttpMessengerSession.shared()
        networking.request(url,
                           methodType: methodType,
                           requestSerializer: requestSerializer,
                           responseDeserializer: responseDeserializer,
                           headers: headers,
                           parameters: parameters,
                           requestProgress: requestProgress,
                           responseProgress: responseProgress,
                           intercepter: intercepter,
                           success: success,
                           failure: failure)
    }
    
    public func request(_ url:URL,
                 methodType: HTTPMethodType,
                 requestSerializer: RequestSerializer = JSONSerializer(),
                 responseDeserializer: ResponseDeserializer = JSONDeserializer(),
                 headers:[String : String]? = nil,
                 parameters:Any? = nil,
                 requestProgress: RequestProgress? = nil,
                 responseProgress: ResponseProgress? = nil,
                 intercepter: ResponseIntercepter? = nil,
                 success: Success? = nil,
                 failure: Failure? = nil) {
        let task = prepareDataTask(url,
                                   methodType: methodType,
                                   requestSerializer: requestSerializer,
                                   responseDeserializer: responseDeserializer,
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
        task?.resume()
    }
    
    public static func request<EncodableData: Encodable>(_ url:URL,
                        methodType: HTTPMethodType,
                        requestSerializer: EncodableSerializer = JSONEncodableSerializer(),
                        responseDeserializer: ResponseDeserializer = JSONDeserializer(),
                        headers:[String : String]? = nil,
                        parameters:EncodableData? = nil,
                        requestProgress: RequestProgress? = nil,
                        responseProgress: ResponseProgress? = nil,
                        intercepter: ResponseIntercepter? = nil,
                        success: Success? = nil,
                        failure: Failure? = nil) {
        let networking: HttpMessengerSession = HttpMessengerSession.shared()
        networking.request(url,
                           methodType: methodType,
                           requestSerializer: requestSerializer,
                           responseDeserializer: responseDeserializer,
                           headers: headers,
                           parameters: parameters,
                           requestProgress: requestProgress,
                           responseProgress: responseProgress,
                           intercepter: intercepter,
                           success: success,
                           failure: failure)
    }
    
    public func request<EncodableData: Encodable>(_ url:URL,
                 methodType: HTTPMethodType,
                 requestSerializer: EncodableSerializer = JSONEncodableSerializer(),
                 responseDeserializer: ResponseDeserializer = JSONDeserializer(),
                 headers:[String : String]? = nil,
                 parameters:EncodableData? = nil,
                 requestProgress: RequestProgress? = nil,
                 responseProgress: ResponseProgress? = nil,
                 intercepter: ResponseIntercepter? = nil,
                 success: Success? = nil,
                 failure: Failure? = nil) {
        let task = prepareDataTask(url,
                                   methodType: methodType,
                                   requestSerializer: requestSerializer,
                                   responseDeserializer: responseDeserializer,
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
        task?.resume()
    }
    
    func makeRequest(_ url:URL,
                     methodType: HTTPMethodType,
                     requestSerializer: RequestSerializer,
                     responseDeserializer: ResponseDeserializer,
                     defaultHeaders: HTTPHeaders,
                     headers:[String : String]? = nil,
                     parameters:Any? = nil) throws -> URLRequest {
        let urlRequest = try URLRequestUtils.makeRequest(url,
                                                         cachePolicy: requestSerializer.cachePolicy,
                                                         timeoutInterval: requestSerializer.timeoutInterval,
                                                         methodType: methodType,
                                                         requestSerializer: requestSerializer,
                                                         responseDeserializer: responseDeserializer,
                                                         defaultHeaders: defaultHeaders,
                                                         headers: headers,
                                                         parameters: parameters)
        urlRequest.printUrls(logger: HttpMessengerSession.logger)
        urlRequest.printHeaders(logger: HttpMessengerSession.logger)
        urlRequest.printBody(logger: HttpMessengerSession.logger)
        return urlRequest
    }
    
    func makeRequest<EncodableData: Encodable>(_ url:URL,
                     methodType: HTTPMethodType,
                     requestSerializer: RequestSerializer,
                     responseDeserializer: ResponseDeserializer,
                     defaultHeaders: HTTPHeaders,
                     headers:[String : String]? = nil,
                     parameters:EncodableData? = nil) throws -> URLRequest {
        let urlRequest = try URLRequestUtils.makeRequest(url,
                                                         cachePolicy: requestSerializer.cachePolicy,
                                                         timeoutInterval: requestSerializer.timeoutInterval,
                                                         methodType: methodType,
                                                         requestSerializer: requestSerializer,
                                                         responseDeserializer: responseDeserializer,
                                                         defaultHeaders: defaultHeaders,
                                                         headers: headers,
                                                         parameters: parameters)
        urlRequest.printUrls(logger: HttpMessengerSession.logger)
        urlRequest.printHeaders(logger: HttpMessengerSession.logger)
        urlRequest.printBody(logger: HttpMessengerSession.logger)
        return urlRequest
    }
    
    private func prepareTask(_ urlRequest: URLRequest,
                             requestProgress: RequestProgress? = nil,
                             responseProgress: ResponseProgress? = nil,
                             intercepter: ResponseIntercepter? = nil,
                             completionHandler: @escaping InnerCompletion) -> URLSessionDataTask? {
        HttpMessengerSession.logger?.d("prepareDataTask")
        do {
            if HttpMessengerSession.kDelegateMode {
                let sessionTask = urlSession.dataTask(with: urlRequest)
                self.sessionDelegate?.register(sessionTask,
                                               intercepter: { [weak self, urlRequest] (data, task, response, error) -> Error? in
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
                                               requestProgress: { [weak self, urlRequest] (task, sent, totalSend, total) in
                                                if let weakSelf = self {
                                                    requestProgress?(weakSelf, urlRequest, sent, totalSend, total)
                                                }
                                               },
                                               responseProgress: { [weak self, urlRequest] (task, rec, totalRec, exp) in
                                                if let weakSelf = self {
                                                    responseProgress?(weakSelf, urlRequest, rec, totalRec, exp)
                                                }
                                               },
                                               completion: { [weak self, urlRequest] (task, response, data, error) in
                                                if let weakSelf = self {
                                                    completionHandler(urlRequest, data, response, error)
                                                }
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
        } catch {
            completionHandler(nil, nil, nil, (error as? HttpMessengerError) ?? .networkingError(from: error))
            return nil
        }
    }
    
    private func prepareDataTask(_ url:URL,
                                 methodType: HTTPMethodType,
                                 requestSerializer: RequestSerializer,
                                 responseDeserializer: ResponseDeserializer,
                                 headers:[String : String]?,
                                 parameters:Any?,
                                 requestProgress: RequestProgress? = nil,
                                 responseProgress: ResponseProgress? = nil,
                                 intercepter: ResponseIntercepter? = nil,
                                 completionHandler: @escaping InnerCompletion) -> URLSessionDataTask? {
        HttpMessengerSession.logger?.d("prepareDataTask")
        do {
            let urlRequest = try URLRequestUtils.makeRequest(url,
                                                             cachePolicy: requestSerializer.cachePolicy,
                                                             timeoutInterval: requestSerializer.timeoutInterval,
                                                             methodType: methodType,
                                                             requestSerializer: requestSerializer,
                                                             responseDeserializer: responseDeserializer,
                                                             defaultHeaders: defaultHeaders,
                                                             headers: headers,
                                                             parameters: parameters)
            urlRequest.printUrls(logger: HttpMessengerSession.logger)
            urlRequest.printHeaders(logger: HttpMessengerSession.logger)
            urlRequest.printBody(logger: HttpMessengerSession.logger)
            if HttpMessengerSession.kDelegateMode {
                let sessionTask = urlSession.dataTask(with: urlRequest)
                self.sessionDelegate?.register(sessionTask,
                                               intercepter: { [weak self, urlRequest] (data, task, response, error) -> Error? in
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
                                               requestProgress: { [weak self, urlRequest] (task, sent, totalSend, total) in
                                                if let weakSelf = self {
                                                    requestProgress?(weakSelf, urlRequest, sent, totalSend, total)
                                                }
                                               },
                                               responseProgress: { [weak self, urlRequest] (task, rec, totalRec, exp) in
                                                if let weakSelf = self {
                                                    responseProgress?(weakSelf, urlRequest, rec, totalRec, exp)
                                                }
                                               },
                                               completion: { [weak self, urlRequest] (task, response, data, error) in
                                                if let weakSelf = self {
                                                    completionHandler(urlRequest, data, response, error)
                                                }
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
        } catch {
            completionHandler(nil, nil, nil, (error as? HttpMessengerError) ?? .networkingError(from: error))
            return nil
        }
    }
}
