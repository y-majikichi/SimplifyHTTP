//
//  BasicRequest.swift
//  HttpMessenger
//
//  Created by Yuto on 2020/12/21.
//

import Foundation

extension URLResponse {
    
    func printUrls(logger: HttpMessengerLogger?) {
        if let logger = logger {
            logger.d("[RESPONSE]==== URL START ====")
            logger.d("[RESPONSE] URL: " + (self.url?.absoluteString ?? "no defined"))
            logger.d("[RESPONSE]==== URL END ====")
        }
        
    }
    
    func printHeaders(logger: HttpMessengerLogger?) {
        if let logger = logger {
            logger.d("[RESPONSE]==== HEADERS START ====")
            if let response = (self as? HTTPURLResponse) {
                for headerKey in response.allHeaderFields.keys {
                    logger.d("[RESPONSE] Key: \(headerKey), Value: \(String(describing: response.allHeaderFields[headerKey]))")
                }
            }
            logger.d("[RESPONSE]==== HEADERS END ====")
        }
        
    }
    
    func statusCodeAsHttpStatus(defaultStatus: HTTPStatus = .badRequest) -> HTTPStatus {
        if let responseSelf = self as? HTTPURLResponse {
            let statusCode = responseSelf.statusCode
            return HTTPStatus.init(rawValue: statusCode) ?? defaultStatus
        } else {
            return defaultStatus
        }
    }
    
    func isSuccess() -> Bool {
        let statusCode = statusCodeAsHttpStatus()
        return (statusCode.rawValue >= HTTPStatus.ok.rawValue && statusCode.rawValue < HTTPStatus.multipleChoices.rawValue)
    }
}

extension URLRequest {

    func printUrls(logger: HttpMessengerLogger?) {
        if let logger = logger {
            logger.d("[REQUEST]==== URL START ====")
            logger.d("[REQUEST] URL: " + (self.url?.absoluteString ?? "no defined"))
            logger.d("[REQUEST]==== URL END ====")
        }
        
    }
    
    func printHeaders(logger: HttpMessengerLogger?) {
        if let logger = logger {
            logger.d("[REQUEST]==== HEADERS START ====")
            if let headers = self.allHTTPHeaderFields {
                for header in headers {
                    logger.d("[REQUEST] Key: " + header.key + ", Value: " + header.value)
                }
            }
            logger.d("[REQUEST]==== HEADERS END ====")
        }
        
    }
    
    func printBody(logger: HttpMessengerLogger?, encoding: String.Encoding? = nil) {
        if let logger = logger {
            logger.d("[REQUEST]==== BODY START ====")
            if let data = self.httpBody {
                if let encoding = encoding {
                    // 指定あり
                    logger.d("[REQUEST] Body(as" + encoding.description + "): " + (String.init(data: data, encoding: encoding) ?? ""))
                } else {
                    logger.d("[REQUEST] Body(as Data): \(data.count) Bytes")
                }
            } else {
                logger.d("[REQUEST] No Body")
            }
            logger.d("[REQUEST]==== BODY END ====")
        }
        
    }
}

class URLRequestUtils {
    
    static func makeHeaders(_ defaultHeaders: HTTPHeaders, sdkHeaders:[String : String]?, append:[String : String]?) -> [String : String]? {
        var fullHeader:[String : String]? = sdkHeaders
        if let defaultHeaders = HTTPHeaders.convert(defaultHeaders) {
            if fullHeader == nil {
                fullHeader = defaultHeaders
            } else {
                fullHeader?.merge(defaultHeaders, uniquingKeysWith: { (current, new) -> String in
                    new
                })
            }
        }
        
        guard append != nil else {
            return fullHeader
        }
        if let append = append {
            if fullHeader == nil {
                fullHeader = append
            } else {
                fullHeader?.merge(append, uniquingKeysWith: { (current, new) -> String in
                    new
                })
            }
        }
        return fullHeader
    }
    
    static func makeHeaders(_ defaultHeaders: HTTPHeaders, sdkHeaders: [String : String]?, append: HTTPHeaders?) -> [String : String]? {
        return makeHeaders(defaultHeaders, sdkHeaders: sdkHeaders, append: HTTPHeaders.convert(append))
    }
    
    private static func makeBaseRequest(_ url:URL,
                            cachePolicy: URLRequest.CachePolicy,
                            timeoutInterval: TimeInterval,
                            methodType: HTTPMethodType,
                            defaultHeaders: HTTPHeaders,
                            headers:[String : String]? = nil) -> URLRequest {
        var request = URLRequest(url: url, cachePolicy: cachePolicy, timeoutInterval: timeoutInterval)
        request.allHTTPHeaderFields = makeHeaders(defaultHeaders, sdkHeaders: request.allHTTPHeaderFields, append: headers)
        request.httpMethod = methodType.rawValue
        return request
    }
    
    static func makeRequest(_ url:URL,
                            cachePolicy: URLRequest.CachePolicy,
                            timeoutInterval: TimeInterval,
                            methodType: HTTPMethodType,
                            requestSerializer: RequestSerializer,
                            responseDeserializer: ResponseDeserializer,
                            defaultHeaders: HTTPHeaders,
                            headers:[String : String]? = nil,
                            parameters:Any? = nil) throws -> URLRequest {
        let postUrl: URL
        var body: Data? = nil
        if methodType != .get || (methodType == .get && requestSerializer.forcedBodyWhenGet) {
            postUrl = url
            body = try requestSerializer.encode(parameters)
        } else {
            // url append
            if let serializer: QueryRequestSerializer = requestSerializer as? QueryRequestSerializer {
                let queries: [URLQueryItem]? = try serializer.encode(parameters)
                if let queries = queries, queries.count > 0 {
                    var queryString = "?"
                    for query in queries {
                        if let value = query.value?.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) {
                            let tmp = query.name + "=" + value
                            if queryString != "?" {
                                queryString += "&"
                            }
                            queryString += tmp
                        }
                    }
                    postUrl = URL(string: (url.absoluteString + queryString))!
                } else {
                    postUrl = url
                }
            } else {
                postUrl = url
            }
        }
        var request = makeBaseRequest(postUrl,
                                      cachePolicy: cachePolicy,
                                      timeoutInterval: timeoutInterval,
                                      methodType: methodType,
                                      defaultHeaders: defaultHeaders,
                                      headers: headers)
        // content-type append
        if request.allHTTPHeaderFields == nil {
            request.allHTTPHeaderFields = [:]
        }
        if let contentType = requestSerializer.contentType {
            request.allHTTPHeaderFields?.updateValue(contentType, forKey: HTTPHeaderKey.contentType.rawValue)
        }
        // Accept append
        if responseDeserializer.acceptContentTypes.count > 0 {
            // to
            let accepts = responseDeserializer.acceptContentTypes.joined(separator: ", ")
            request.allHTTPHeaderFields?.updateValue(accepts, forKey: HTTPHeaderKey.accept.rawValue)
        } else {
            request.allHTTPHeaderFields?.updateValue("*/*", forKey: HTTPHeaderKey.accept.rawValue)
        }
        request.httpBody = body
        return request
    }
    
    static func makeRequest<EncodableData: Encodable>(_ url:URL,
                            cachePolicy: URLRequest.CachePolicy,
                            timeoutInterval: TimeInterval,
                            methodType: HTTPMethodType,
                            requestSerializer: EncodableSerializer,
                            responseDeserializer: ResponseDeserializer,
                            defaultHeaders: HTTPHeaders,
                            headers:[String : String]? = nil,
                            parameters:EncodableData? = nil) throws -> URLRequest {
        let postUrl: URL
        var body: Data? = nil
        if methodType != .get || (methodType == .get && requestSerializer.forcedBodyWhenGet) {
            postUrl = url
            body = try requestSerializer.encode(parameters)
        } else {
            // url append
            if let serializer: QueryRequestSerializer = requestSerializer as? QueryRequestSerializer {
                let queries: [URLQueryItem]? = try serializer.encode(parameters)
                if let queries = queries, queries.count > 0 {
                    var queryString = "?"
                    for query in queries {
                        if let value = query.value?.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) {
                            let tmp = query.name + "=" + value
                            if queryString != "?" {
                                queryString += "&"
                            }
                            queryString += tmp
                        }
                    }
                    postUrl = URL(string: (url.absoluteString + queryString))!
                } else {
                    postUrl = url
                }
            } else {
                postUrl = url
            }
        }
        var request = makeBaseRequest(postUrl,
                                      cachePolicy: cachePolicy,
                                      timeoutInterval: timeoutInterval,
                                      methodType: methodType,
                                      defaultHeaders: defaultHeaders,
                                      headers: headers)
        // content-type append
        if request.allHTTPHeaderFields == nil {
            request.allHTTPHeaderFields = [:]
        }
        if let contentType = requestSerializer.contentType {
            request.allHTTPHeaderFields?.updateValue(contentType, forKey: HTTPHeaderKey.contentType.rawValue)
        }
        // Accept append
        if responseDeserializer.acceptContentTypes.count > 0 {
            // to
            let accepts = responseDeserializer.acceptContentTypes.joined(separator: ", ")
            request.allHTTPHeaderFields?.updateValue(accepts, forKey: HTTPHeaderKey.accept.rawValue)
        } else {
            request.allHTTPHeaderFields?.updateValue("*/*", forKey: HTTPHeaderKey.accept.rawValue)
        }
        request.httpBody = body
        return request
    }
    
    static func makeUploadRequest(_ url:URL,
                                  cachePolicy: URLRequest.CachePolicy,
                                  timeoutInterval: TimeInterval,
                                  methodType: HTTPMethodType,
                                  defaultHeaders: HTTPHeaders,
                                  headers:[String : String]? = nil) throws -> URLRequest {
        return makeBaseRequest(url,
                               cachePolicy: cachePolicy,
                               timeoutInterval: timeoutInterval,
                               methodType: methodType,
                               defaultHeaders: defaultHeaders,
                               headers: headers)
    }
    
    static func makeDownloadRequest(_ url:URL,
                                    cachePolicy: URLRequest.CachePolicy,
                                    timeoutInterval: TimeInterval,
                                    methodType: HTTPMethodType,
                                    requestSerializer: RequestSerializer,
                                    defaultHeaders: HTTPHeaders,
                                    headers:[String : String]? = nil) throws -> URLRequest {
        return makeBaseRequest(url,
                               cachePolicy: cachePolicy,
                               timeoutInterval: timeoutInterval,
                               methodType: methodType,
                               defaultHeaders: defaultHeaders,
                               headers: headers)
    }
}
