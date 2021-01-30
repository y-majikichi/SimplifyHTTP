//
//  HttpMessengerError.swift
//  HttpMessenger
//
//  Created by Yuto on 2020/12/18.
//

import Foundation

public enum HttpMessengerError: Error {
    
    case URLError(at: URL)
    case encoderError
    case decoderError
    case unknownError
    case networkingError(from: Error)
    case statusError(status: HTTPStatus)
    case responseError
    case invalidSerializer(now: RequestSerializer, pormise: RequestSerializer)
    case invalidSerializedType
    case failedSerialize(from: Error)
}

extension HttpMessengerError {
    var url: URL? {
        switch self {
        case .URLError(let url):
            return url
        default:
            return nil
        }
    }
    
    var underlyingError: Error? {
        switch self {
        case .networkingError(from: let error):
            return error
        case .failedSerialize(from: let error):
            return error
        default:
            return nil
        }
    }
    
    var status: HTTPStatus? {
        switch self {
        case .statusError(status: let status):
            return status
        default:
            return nil
        }
    }
}

extension HttpMessengerError {
    var nowSerializer: RequestSerializer? {
        switch self {
        case .invalidSerializer(now: let now, pormise: _):
            return now
        default:
            return nil
        }
    }
    
    var promiseSerializer: RequestSerializer? {
        switch self {
        case .invalidSerializer(now: _, pormise: let promise):
            return promise
        default:
            return nil
        }
    }
}

extension HttpMessengerError {
    
    var localizedDescription: String {
        let ret: String
        switch self {
        case .URLError(at: let url):
            ret = "URL invalid : " + url.absoluteString
        case .encoderError:
            ret = "Encoder Error"
        case .decoderError:
            ret = "Decorder Error"
        case .networkingError(from: let error):
            ret = error.localizedDescription
        case .statusError(status: let status):
            ret = "Invalid Status : \(status.rawValue)"
        case .responseError:
            ret = "Response Error"
        case .invalidSerializer(now: _, pormise: _):
            ret = "Invalid Serializer"
        case .failedSerialize(from: let error):
            ret = error.localizedDescription
        default:
            ret = "Unkown Error"
        }
        return ret
    }
}
