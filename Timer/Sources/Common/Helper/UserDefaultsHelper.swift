//
//  UserDefaultsHelper.swift
//  Timer
//
//  Created by Jason Hwang on 4/19/24.
//

import Foundation

// MARK: - A wrapper struct for User defaults
struct UserDefaultsHelper {
    static var time: Int {
        get { UserDefaults.standard.integer(forKey: Constants.timeKey) }
        set { UserDefaults.standard.set(newValue, forKey: Constants.timeKey) }
    }
    
    static var pomodoroRestTime: Int {
        get { UserDefaults.standard.integer(forKey: Constants.pomodoroRestTimeKey) }
        set { UserDefaults.standard.set(newValue, forKey: Constants.pomodoroRestTimeKey) }
    }
    
    static var pomodoroLongRestInterval: Int {
        get { UserDefaults.standard.integer(forKey: Constants.pomodoroLongRestIntervalKey) }
        set { UserDefaults.standard.set(newValue, forKey: Constants.pomodoroLongRestIntervalKey) }
    }
    
    static var pomodoroLongRestTime: Int {
        get { UserDefaults.standard.integer(forKey: Constants.pomodoroLongRestTimeKey) }
        set { UserDefaults.standard.set(newValue, forKey: Constants.pomodoroLongRestTimeKey) }
    }
}
