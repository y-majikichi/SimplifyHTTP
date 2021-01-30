//
//  ContentTypeModel.swift
//  HttpMessenger
//
//  Created by Yuto on 2020/12/11.
//

import Cocoa

enum ContentTypeModel: String, Codable {
    case JSON = "application/json"
    case XML = "application/xml"
    case XML_TEXT = "text/xml"
    case URL_ENCODED = "application/x-www-form-urlencoded"
    case OTHERS = "others"
}
