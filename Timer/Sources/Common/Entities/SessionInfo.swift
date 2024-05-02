//
//  SessionInfo.swift
//  Timer
//
//  Created by Jason Hwang on 5/2/24.
//

import Foundation

// MARK: - Pomodoro session info.
struct SessionInfo: Equatable{
    // session number
    var order: Int
    // session type
    var type: SessionType
    // session state
    var state: SessionState
    // seconds
    var time: Int
}
