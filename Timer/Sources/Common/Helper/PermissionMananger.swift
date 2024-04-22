//
//  PermissionMananger.swift
//  Timer
//
//  Created by Jason Hwang on 4/19/24.
//

import Foundation
import UserNotifications

struct PermissionMananger {
    static func requestNotiPermission() async throws {
        let center = UNUserNotificationCenter.current()
        do {
            try await center.requestAuthorization(options: [.alert, .sound, .badge])
        } catch (let error) {
            print("Permission error : \(error.localizedDescription)")
        }
    }
    
    static func notiPermissionStatus() async -> Bool {
        let center = UNUserNotificationCenter.current()
        
        // Obtain the notification settings.
        let settings = await center.notificationSettings()
        
        // Verify the authorization status.
        if (settings.authorizationStatus == .authorized) ||
            (settings.authorizationStatus == .provisional) {
            return true
        } else { return false }
    }
}
