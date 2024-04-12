//
//  TimerFeature.swift
//  Timer
//
//  Created by Jason Hwang on 4/11/24.
//

import Foundation
import Combine
import ComposableArchitecture

@Reducer
struct TimerFeature {
    @Dependency(\.continuousClock) var clock
    
    @ObservableState
    struct State: Equatable {
        // 남은 시간
        var timeRemaining: Int = 0
        // 종료 Alert 보여주었는지 여부
        var showAlert: Bool = false
        // Timer 가 살아있는지
        var isTimerRunning: Bool = false
//        // Timer
//        var timer: AnyCancellable?
//        // 시간 범위 (0분~25분)
//        let durationRange = Array(0...1500)
    }
    
    enum Action {
        case startTimer
        case pauseOrResumeTimer
        case stopTimer
        case tick
    }
    
    
    var body: some Reducer<State, Action> {
        Reduce{ state, action in
            switch action {
            case .startTimer:
                // timer 시작
                state.isTimerRunning = true
                return .run { send in
                        for await _ in self.clock.timer(interval: .seconds(1)) {
                            await send(.tick)
                        }
                }.cancellable(id: "timer")
            case .pauseOrResumeTimer:
                if state.isTimerRunning {
                    state.isTimerRunning = false
                    return .cancel(id: "timer")
                } else {
                    state.isTimerRunning = true
                    // timer 재시작
                    return .run(operation: {send in
                        await send(.startTimer)
                    })
                }
            case .stopTimer:
                return .cancel(id: "timer")
            case .tick:
                if state.timeRemaining > 0 {
                    state.timeRemaining -= 1
                    return .none
                } else {
                    state.showAlert = true
                    state.isTimerRunning = false
                    return .cancel(id: "timer")
                }
            }
        }
    }
}
