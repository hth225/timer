//
//  PomodoroState.swift
//  Timer
//
//  Created by Jason Hwang on 4/23/24.
//

import Foundation

// MARK: Pomodoro state type.
enum PomodoroState {
    /// active. But, not started
    case active
    /// focus session
    case focus
    /// rest session
    case rest
    /// Pomodoro mode disabled
    case disabled
}
