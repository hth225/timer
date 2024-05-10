//
//  BackgroundTaskHelper.swift
//  Timer
//
//  Created by Jason Hwang on 5/9/24.
//

import Foundation
import BackgroundTasks

// e -l objc -- (void)[[BGTaskScheduler sharedScheduler]_simulateLaunchForTaskWithIdentifier:@"io.tuist.Timer-background.notification"]
struct BackgroundTaskHelper {
    func scheduleAppRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: Constants.backgroundTaskIdentifier)
        // Fetch no earlier than 15 minutes from now.
        request.earliestBeginDate = Date(timeIntervalSinceNow: 25 * 60)
        
        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            print("Could not schedule app refresh: \(error)")
        }
    }
}
