//
//  HttpMessengerSession+Upload.swift
//  HttpMessenger
//
//  Created by Yuto on 2021/01/12.
//

import Foundation

/// Upload
extension HttpMessengerSession {
    
    public func upload(_ url:URL,
                 methodType: HTTPMethodType,
                 requestSerializer: RequestSerializer = JSONSerializer(),
                 responseDeserializer: ResponseDeserializer = JSONDeserializer(),
                 headers:[String : String]? = nil,
                 data: Data?,
                 requestProgress: RequestProgress? = nil,
                 responseProgress: ResponseProgress? = nil,
                 intercepter: ResponseIntercepter? = nil,
                 success: Success? = nil,
                 failure: Failure? = nil) -> URLSessionUploadTask? {
        let task = prepareUploadTask(url,
                                     methodType: methodType,
                                     requestSerializer: requestSerializer,
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
        task?.resume()
        return task
    }
    
    private func prepareUploadTask(_ url:URL,
                                 methodType: HTTPMethodType,
                                 requestSerializer: RequestSerializer,
                                 headers:[String : String]?,
                                 data: Data?,
                                 requestProgress: RequestProgress? = nil,
                                 responseProgress: ResponseProgress? = nil,
                                 intercepter: ResponseIntercepter? = nil,
                                 completionHandler: @escaping InnerCompletion) -> URLSessionUploadTask? {
        HttpMessengerSession.logger?.d("prepareUploadTask")
        do {
            let urlRequest = try URLRequestUtils.makeUploadRequest(url,
                                                                   cachePolicy: requestSerializer.cachePolicy,
                                                                   timeoutInterval: requestSerializer.timeoutInterval,
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
        } catch {
            completionHandler(nil, nil, nil, (error as? HttpMessengerError) ?? .networkingError(from: error))
            return nil
        }
    }
}
