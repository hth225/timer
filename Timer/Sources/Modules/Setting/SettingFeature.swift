//
//  SettingFeature.swift
//  Timer
//
//  Created by Jason Hwang on 5/14/24.
//

import Foundation
import ComposableArchitecture

@Reducer
struct SettingFeature {
    struct State: Equatable {
        var pomodoroActive = false
        var selectedShortBreak = 5
        var selectedLongBreak = 15
        var selectedInterval = 3
    }
    
    enum Action {
        case setup
        case onPomodoroModeChanged(Bool)
        case onShortBreakChanged(Int)
        case onLongBreakChanged(Int)
        case onIntervalChanged(Int)
    }
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .setup:
                state.pomodoroActive = UserDefaultsHelper.pomodoroState == PomodoroState.active
                state.selectedShortBreak = UserDefaultsHelper.pomodoroRestTime / 60
                state.selectedLongBreak = UserDefaultsHelper.pomodoroLongRestTime / 60
                state.selectedInterval = UserDefaultsHelper.pomodoroLongRestInterval
                return .none
            case let .onPomodoroModeChanged(active):
                state.pomodoroActive = active
                UserDefaultsHelper.pomodoroState = active ? PomodoroState.active : PomodoroState.disabled
                return .none
            case let .onShortBreakChanged(time):
                state.selectedShortBreak = time
                UserDefaultsHelper.pomodoroRestTime = state.selectedShortBreak * 60
                return .none
            case let .onLongBreakChanged(time):
                state.selectedLongBreak = time
                UserDefaultsHelper.pomodoroLongRestTime = state.selectedLongBreak * 60
                return .none
            case let .onIntervalChanged(interval):
                state.selectedInterval = interval
                UserDefaultsHelper.pomodoroLongRestInterval = state.selectedInterval
                return .none
            }
        }
    }
}
