//
//  AppDelegate.swift
//  AD_App
//
//  Created by Chun-kit Ho on 17/10/2018.
//  Copyright © 2018 Chun-kit Ho. All rights reserved.
//

import UIKit
import EZSwiftExtensions
import KeychainSwift
import Reachability
import UserNotifications
import SwiftyJSON

var v_host = "http://ad-backend.fqs3taypzi.ap-southeast-1.elasticbeanstalk.com"
//var v_host = "http://192.168.1.106:8081"
var reachability = Reachability()!

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
//        UIApplication.shared.registerForRemoteNotifications()
        registerForPushNotifications()
        UNUserNotificationCenter.current().delegate = self
        
        let keychain = KeychainSwift()
        let accessToken = keychain.get("accessToken")
        
        if accessToken != nil
        {
            let mainStoryboard:UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
            let homePage = mainStoryboard.instantiateViewController(withIdentifier: "TabBarViewController") as! TabBarViewController
            self.window?.rootViewController = homePage
        }
        
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }

    func registerForPushNotifications() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) {
            (granted, error) in
            print("Permission granted: \(granted)")
            
            guard granted else { return }
            self.getNotificationSettings()
        }
    }

    func getNotificationSettings() {
        UNUserNotificationCenter.current().getNotificationSettings { (settings) in
            print("Notification settings: \(settings)")
            guard settings.authorizationStatus == .authorized else { return }
            DispatchQueue.main.async {
                UIApplication.shared.registerForRemoteNotifications()
            }
        }
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void)
    {
        completionHandler([.alert, .badge, .sound])
    }
    
    func application(_ application: UIApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let tokenParts = deviceToken.map { data -> String in
            return String(format: "%02.2hhx", data)
        }
        
        let token = tokenParts.joined()
        
        let keychain = KeychainSwift()
        let accessToken = keychain.get("accessToken")
        
        if accessToken != nil
        {
            if reachability.connection != .none {
                let url = URL(string: "\(v_host)/api/notification/ios")
                
                var request = URLRequest(url: url!)
                
                request.httpMethod = "POST"
                request.addValue("\(accessToken!)", forHTTPHeaderField: "Authorization")
                request.addValue("application/json", forHTTPHeaderField: "content-type")
                request.addValue("application/json", forHTTPHeaderField: "Accept")
                
                let postString = ["token": token] as [String: String]
                
                do {
                    request.httpBody = try JSONSerialization.data(withJSONObject: postString, options: .prettyPrinted)
                } catch let error {
                    print(error.localizedDescription)
                }
                
                let task = URLSession.shared.dataTask(with: request) { (data: Data?, response: URLResponse?, error: Error?) in
                    if error != nil
                    {
                        print("error=\(String(describing: error))")
                        return
                    }
                    guard let data = data else {
                        return
                    }
                    do
                    {
                        let json = try JSON(data: data)
                        
                        if json["success"].bool! {
                            print("success")
                        } else {
                            print("error in json")
                        }
                        
                    } catch {
                        print("error=\(String(describing: error))")
                    }
                }
                task.resume()
            }
        }
        print("Device Token: \(token)")
    }
    
    func application(_ application: UIApplication,
                     didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Failed to register: \(error)")
    }
    
}

