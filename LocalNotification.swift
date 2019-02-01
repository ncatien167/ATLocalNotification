//
//  LocalNotification.swift
//  LocalNotification
//
//  Created by Apple on 12/26/18.
//  Copyright © 2018 Anh Tien. All rights reserved.
//

import UIKit
import UserNotifications

@available(iOS 10.0, *)
class NotificationManager: NSObject, UNUserNotificationCenterDelegate {
    
    static let shared: NotificationManager = {
        return NotificationManager()
    }()
    
    var isAuthorized = false
    
    // requestAuthorization to ask the user’s permission for using notification.
    func requestAuthorization() {
        let options:UNAuthorizationOptions = [.badge, .alert, .sound]
        UNUserNotificationCenter.current().requestAuthorization(options: options) { (granted: Bool, error: Error?) in
            if granted {
                print("Notification Authorized")
                self.isAuthorized = true
            } else {
                self.isAuthorized = false
                print("Notification Not Authorized")
            }
        }
        UNUserNotificationCenter.current().delegate = self
    }
    
    //Handle get all list of notification request
    func getAllPendingNotifications(completion: @escaping ([UNNotificationRequest]?) -> Void){
        UNUserNotificationCenter.current().getPendingNotificationRequests { (requests: [UNNotificationRequest]) in
            return completion(requests)
        }
    }
    
    //Handle cancel all notification
    func cancelAllNotifcations() {
        getAllPendingNotifications { (requests: [UNNotificationRequest]?) in
            if let requestsIds = requests{
                UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: requestsIds.map{$0.identifier})
            }
        }
    }
    
}

//MARK: - UNUserNotificationCenterDelegate
extension NotificationManager {
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.alert, .badge, .sound])
        print(notification.request.content.userInfo)
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        
        print("Did tap on the notification",response.notification.request.content)
        completionHandler()
    }
    
}

@available(iOS 10.0, *)
class NotificationScheduler {
    
    func schedule(_ identifier: String, _ title: String, _ body: String, _ fireDate: Date, _ repeatInterval: RepeatingInterval, _ repeats: Bool = false, _ sound: UNNotificationSound = .default, userInfo: [String : Any] = [:]) {
        
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = sound
        content.badge = UIApplication.shared.applicationIconBadgeNumber + 1 as NSNumber
        content.userInfo = userInfo
        
        let trigger = UNCalendarNotificationTrigger.init(dateMatching: convertDateToDateComponent(with: fireDate, repeatInterval: repeatInterval), repeats: repeats)
        
        let request = UNNotificationRequest.init(identifier: identifier, content: content, trigger: trigger)
        
        let center = UNUserNotificationCenter.current()
        center.add(request) { (error) in
            if let error = error {
                NSLog("Created Notification Failed: %@",error.localizedDescription)
            } else {
                NSLog("Notification Created Successfully.")
            }
        }
    }

}

extension NotificationScheduler {
    
    fileprivate func convertDateToDateComponent(with fireDate: Date, repeatInterval: RepeatingInterval) -> DateComponents {
        var dateComponents = Calendar.current.dateComponents([.minute, .hour, .day, .weekday, .month, .year], from: fireDate)
        
        if repeatInterval != .none {
            switch repeatInterval {
            case .minute:
                dateComponents = Calendar.current.dateComponents([.second], from: fireDate)
            case .hourly:
                dateComponents = Calendar.current.dateComponents([.minute], from: fireDate)
            case .daily:
                dateComponents = Calendar.current.dateComponents([.minute, .hour], from: fireDate)
            case .weekly:
                dateComponents = Calendar.current.dateComponents([.minute, .hour, .weekday], from: fireDate)
            case .monthly:
                dateComponents = Calendar.current.dateComponents([.minute, .hour, .day], from: fireDate)
            case .yearly:
                dateComponents = Calendar.current.dateComponents([.minute, .hour, .day, .year], from: fireDate)
            default:
                break
            }
        }
        
        return dateComponents
    }
    
}

// Repeating Interval Times
public enum RepeatingInterval: String {
    case none, minute, hourly, daily, weekly, monthly, yearly
}

// Extension Create Date from Value
extension Date {

    func createDate(forMonth month: Int, year: Int, day: Int, hour: Int, minute: Int) -> Date {
        var components = DateComponents()
        components.day = day
        components.month = month
        components.year = year
        components.hour = hour
        components.minute = minute
        
        let gregorian = Calendar(identifier: .gregorian)
        return gregorian.date(from: components)!
    }
    
}
