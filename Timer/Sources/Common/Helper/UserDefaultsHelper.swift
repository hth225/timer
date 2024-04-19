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
    
}
