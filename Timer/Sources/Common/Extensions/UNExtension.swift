//
//  UNExtension.swift
//  Timer
//
//  Created by Jason Hwang on 4/19/24.
//

import Foundation
import UserNotifications

extension UNUserNotificationCenter {
    func addNoti(id: String, time: Int) {
        // content 만들기
        let content = UNMutableNotificationContent()
        content.title = "Timer completed"
        content.body = "\(Int(time / 60))minutes"
        content.sound = .default
        
        // trigger 만들기
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(time), repeats: false)
        
        // request 만들기
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
    }
    
    func removeAllPendingTimers() {
        self.removeAllPendingNotificationRequests()
    }
}
