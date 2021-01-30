//
//  HttpMessengerSession+Donwload.swift
//  HttpMessenger
//
//  Created by Yuto on 2021/01/12.
//

import Foundation

/// Download
extension HttpMessengerSession {
    
    public func download(_ url:URL,
                 methodType: HTTPMethodType,
                 requestSerializer: RequestSerializer = JSONSerializer(),
                 responseDeserializer: DownloadResponseDeserializer,
                 headers:[String : String]? = nil,
                 requestProgress: RequestProgress? = nil,
                 responseProgress: ResponseProgress? = nil,
                 intercepter: ResponseIntercepter? = nil,
                 success: Success? = nil,
                 failure: Failure? = nil) -> DownloadTask? {
        let task = prepareDownloadTask(url,
                                       methodType: methodType,
                                       requestSerializer: requestSerializer,
                                       responseDeserializer: responseDeserializer,
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
        task?.downloadTask.resume()
        return task
    }
    
    private func prepareDownloadTask(_ url:URL,
                                 methodType: HTTPMethodType,
                                 requestSerializer: RequestSerializer,
                                 responseDeserializer: DownloadResponseDeserializer,
                                 headers:[String : String]?,
                                 requestProgress: RequestProgress? = nil,
                                 responseProgress: ResponseProgress? = nil,
                                 intercepter: ResponseIntercepter? = nil,
                                 completionHandler: @escaping InnerCompletion) -> DownloadTask? {
        HttpMessengerSession.logger?.d("prepareDownloadTask")
        do {
            let urlRequest = try URLRequestUtils.makeDownloadRequest(url,
                                                                     cachePolicy: requestSerializer.cachePolicy,
                                                                     timeoutInterval: requestSerializer.timeoutInterval,
                                                                     methodType: methodType,
                                                                     requestSerializer: requestSerializer,
                                                                     defaultHeaders: defaultHeaders,
                                                                     headers: headers)
            if HttpMessengerSession.kDelegateMode {
                let sessionTask = urlSession.downloadTask(with: urlRequest)
                self.sessionDelegate?.register(sessionTask,
                                               downloadDeserializer: responseDeserializer,
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
                return DownloadTask(sessionTask, saveURL: responseDeserializer.saveURL)
            } else {
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
                return DownloadTask(task, saveURL: responseDeserializer.saveURL)
            }
        } catch {
            completionHandler(nil, nil, nil, (error as? HttpMessengerError) ?? .networkingError(from: error))
            return nil
        }
    }
    
    public func resume(_ downloadTask: DownloadTask,
                       responseDeserializer: DownloadResponseDeserializer,
                       responseProgress: ResponseProgress? = nil,
                       intercepter: ResponseIntercepter? = nil,
                       success: Success? = nil,
                       failure: Failure? = nil) -> DownloadTask? {
        if HttpMessengerSession.kDelegateMode, let resumeData = downloadTask.resumeData {
            let sessionTask = urlSession.downloadTask(withResumeData: resumeData)
            self.sessionDelegate?.register(sessionTask,
                                           downloadDeserializer: responseDeserializer,
                                           intercepter: { [weak self] (data, task, response, error) -> Error? in
                                            if let weakSelf = self {
                                                // FIX Request
                                                return weakSelf.intercept(intercepter,
                                                                          urlRequest: task.currentRequest ?? task.originalRequest ?? URLRequest(url: URL(string: "https://dummy")!),
                                                                          data: data,
                                                                          urlResponse: response,
                                                                          error: error)
                                            } else {
                                                return nil
                                            }
                                           },
                                           responseProgress: { [weak self] (task, rec, totalRec, exp) in
                                            if let weakSelf = self {
                                                responseProgress?(weakSelf, task.currentRequest ?? task.originalRequest, rec, totalRec, exp)
                                            }
                                           },
                                           completion: { [weak self] (task, response, data, error) in
                                            if let weakSelf = self {
                                                weakSelf.analysisResponse(urlRequest: task.currentRequest ?? task.originalRequest,
                                                                          responseDeserializer: responseDeserializer,
                                                                          data: data,
                                                                          urlResponse: response,
                                                                          error: error,
                                                                          success: success,
                                                                          failure: failure)
                                            }
                                           })
            requestArrays.append((sessionTask.currentRequest ?? sessionTask.originalRequest ?? URLRequest(url: URL(string: "https://dummy")!), sessionTask))
            return DownloadTask(sessionTask, saveURL: responseDeserializer.saveURL)
        } else {
            return nil
        }
    }
}
