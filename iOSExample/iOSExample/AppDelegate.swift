//
//  AppDelegate.swift
//  iOSExample
//
//  Created by Yuto on 2021/01/03.
//

import UIKit
import HttpMessenger

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        HttpMessengerSession.logger = SystemNetworkingActivityLogger(.verbose)
        
        return true
    }

}

