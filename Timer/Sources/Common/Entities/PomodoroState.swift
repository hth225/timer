//
//  PomodoroState.swift
//  Timer
//
//  Created by Jason Hwang on 4/23/24.
//

import Foundation

// MARK: Pomodoro state type.
enum PomodoroState: Int, Decodable, Encodable{
    /// Pomodoro mode disabled
    case disabled = 0
    /// active. But, not started
    case active = 1
    /// focus session
    case focus = 2
    /// rest session
    case rest = 3
}
