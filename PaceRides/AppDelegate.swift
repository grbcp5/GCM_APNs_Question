//
//  AppDelegate.swift
//  PaceRides
//
//  Created by Grant Broadwater on 11/6/18.
//  Copyright © 2018 PaceRides. All rights reserved.
//

import UIKit
import CoreData
import UserNotifications
import Firebase

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    let notificationCenter = NotificationCenter.default
    let NotificationsAuthorizationMayHaveChanged = Notification.Name("NotificationsAuthorizationMayHaveChanged")
    var fcmToken: String?
    

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        FirebaseApp.configure()
        
        // Instaciate Window
        if self.window == nil {
            self.window = UIWindow()
        }
        guard let window = self.window else {
            return false
        }
        
        // Set View Controller
        let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let welcomeViewController = mainStoryboard.instantiateViewController(withIdentifier: "WelcomeViewController")
        window.rootViewController = welcomeViewController
        window.makeKeyAndVisible()
        
        // User Notification Configuration
        UNUserNotificationCenter.current().delegate = self
        Messaging.messaging().delegate = self
        Messaging.messaging().shouldEstablishDirectChannel = true
        Messaging.messaging().useMessagingDelegateForDirectChannel = true
        self.checkNotificationAuthorization()
        UIApplication.shared.registerForRemoteNotifications()
        
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
        
        Messaging.messaging().shouldEstablishDirectChannel = false
        Messaging.messaging().useMessagingDelegateForDirectChannel = false
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        
        Messaging.messaging().shouldEstablishDirectChannel = false
        Messaging.messaging().useMessagingDelegateForDirectChannel = false
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
        
        Messaging.messaging().shouldEstablishDirectChannel = true
        Messaging.messaging().useMessagingDelegateForDirectChannel = true
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        
        Messaging.messaging().shouldEstablishDirectChannel = true
        Messaging.messaging().useMessagingDelegateForDirectChannel = true
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        
        Messaging.messaging().shouldEstablishDirectChannel = false
        Messaging.messaging().useMessagingDelegateForDirectChannel = false
    }

    // MARK: - Core Data stack

    lazy var persistentContainer: NSPersistentContainer = {
        /*
         The persistent container for the application. This implementation
         creates and returns a container, having loaded the store for the
         application to it. This property is optional since there are legitimate
         error conditions that could cause the creation of the store to fail.
        */
        let container = NSPersistentContainer(name: "PaceRides")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                 
                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()

    // MARK: - Core Data Saving support

    func saveContext () {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }

}


extension AppDelegate: UNUserNotificationCenterDelegate {
    
    
    func getNotificationAuthorization(completion: @escaping (UNNotificationSettings) -> Void) {
        UNUserNotificationCenter.current().getNotificationSettings(completionHandler: completion)
    }
    
    
    func requestNotificationAuthorization(completion: (() -> Void)? = nil) {
        
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .badge, .sound]
        ) { granted, error in
            
            guard error == nil else {
                
                print("Error")
                print(error!.localizedDescription)
                
                return
            }
            
            if let completion = completion {
                completion()
            }
        }
    }
    
    func checkNotificationAuthorization() {
        
        
        self.notificationCenter.post(
            name: self.NotificationsAuthorizationMayHaveChanged,
            object: self
        )
        
        self.getNotificationAuthorization() { setting in
            
            switch setting.authorizationStatus {
                
            case .denied:
                fallthrough
            case .notDetermined:
                fallthrough
            case .provisional:
                break
            case .authorized:
                break
            }
            
        }
        
    }
    
    
    func openApplicationSettings() {
        guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
            return
        }
        
        if UIApplication.shared.canOpenURL(settingsUrl) {
            UIApplication.shared.open(settingsUrl) { success in
                print("Setting is opened: \(success)")
            }
        }
    }
    
    
    func sendLocalNotificaiton(withTitle title: String, andBody body: String, after timeInterval: Double = 1) {
        
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = UNNotificationSound.default
        
        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: timeInterval,
            repeats: false
        )
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            
            guard error == nil else {
                print("Error")
                print(error!.localizedDescription)
                return
            }
        }
    }
    
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        
        Messaging.messaging().apnsToken = deviceToken
        
        let hexToken = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        
        print()
        print("application:didRegisterForRemoteNotificationsWithDeviceToken")
        print("Token: \(hexToken)")
    }
    
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        
        print()
        print("application:didFailToRegisterForRemoteNotificationsWithError")
        print("Error: \(error.localizedDescription)")
    }
    
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        
        print()
        print("userNotificationCenter:didRecieve:withCompletionHandler")
        print("response UUID: \(response.notification.request.identifier)")
        
        completionHandler()
    }
    
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        
        Messaging.messaging().appDidReceiveMessage(notification.request.content.userInfo)
        
        print()
        print("userNotificationCenter:willPresent:withCompletionHandler")
        print("notification UUID: \(notification.request.identifier)")
        
        completionHandler([.alert, .sound])
    }
    
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any]) {
        
        Messaging.messaging().appDidReceiveMessage(userInfo)
        
        print()
        print("application:didReceiveRemoteNotification")
        print("User Info: \(userInfo)")
    }
    
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        
        Messaging.messaging().appDidReceiveMessage(userInfo)
        
        print()
        print("application:didReceiveRemoteNotification:fetchCompletionHandler")
        print("User Info: \(userInfo)")
        
        completionHandler(UIBackgroundFetchResult.newData)
    }
}


extension AppDelegate: MessagingDelegate {
    
    
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String) {
        
        self.fcmToken = fcmToken
        
        print()
        print("Firebase registration token: \(fcmToken)")
        
        let dataDict:[String: String] = ["token": fcmToken]
        NotificationCenter.default.post(name: Notification.Name("FCMToken"), object: nil, userInfo: dataDict)
    }
    
    
    func messaging(_ messaging: Messaging, didReceive remoteMessage: MessagingRemoteMessage) {
        
        print()
        print("messaging:didRecieve")
        print("Remote Message: \(remoteMessage)")
        
    }
    
    
    func subscribe(toTopic topic: String, completion: ((Error?) -> Void)? = nil) -> Bool {
        
        guard self.fcmToken != nil else {
            return false
        }
        
        Messaging.messaging().subscribe(toTopic: topic, completion: completion)
        
        return true
    }
    
    
    func unsubscribe(fromTopic topic: String, completion: ((Error?) -> Void)? = nil) -> Bool {
        
        guard self.fcmToken != nil else {
            return false
        }
        
        Messaging.messaging().unsubscribe(fromTopic: topic, completion: completion)
        
        return true
    }
}

