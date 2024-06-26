//
//  Constants.swift
//  Timer
//
//  Created by Jason Hwang on 4/19/24.
//

import Foundation
import SwiftUI

struct Constants {
    static let timeKey = "timeKey"
    
    static let pomodoroFocusTimeKey = "pomodoroFocusTimeKey"
    static let pomodoroStateKey = "pomodoroStateKey"
    static let pomodoroRestTimeKey = "pomodoroRestTimeKey"
    static let pomodoroLongRestIntervalKey = "pomodoroLongRestIntervalKey"
    static let pomodoroLongRestTimeKey = " pomodoroLongRestTimeKey"
    
    // Time related
    static let secondToProgress = 0.00028
    static let secondToAngle = Angle(degrees: 0.0948)
    
    // background refresh
    static let backgroundTaskIdentifier = "io.tuist.Timer-background.notification"
    static let pomodoroLatestNotiDate = "pomodoroLatestNotiDate"
    static let pomodoroLatestAddedIndex = "pomodoroLatestAddedIndex"
    
}
