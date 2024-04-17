//
//  TimerFeature.swift
//  Timer
//
//  Created by Jason Hwang on 4/11/24.
//

import Foundation
import Combine
import ComposableArchitecture
import SwiftUI

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
        
        // app 이 background 로 진입한 시간
        var appDidEnterBackgroundDate: Date?
        
        // Circle slider progress. (max: 1.0)
        var progress = 0.0
        // Circle slider rotation angle
        var rotationAngle = Angle(degrees: 0)
        
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
        case appDidEnterBackground
        case appWillEnterForeground
        case timeChanged(CGPoint)
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
            case .appDidEnterBackground:
                state.appDidEnterBackgroundDate = Date()
                return .none
            case .appWillEnterForeground:
                guard let previousDate = state.appDidEnterBackgroundDate else { return .none }
                let calendar = Calendar.current
                let difference = calendar.dateComponents([.second], from: previousDate, to: Date())
                let seconds = difference.second!
                print("Time diff:\(seconds)")
                state.timeRemaining -= seconds
                return .none
            case let .timeChanged(location):
                // Create a Vector for the location (reversing the y-coordinate system on iOS)
                let vector = CGVector(dx: location.x, dy: -location.y)
                
                // Calculate the angle of the vector
                let angleRadians = atan2(vector.dx, vector.dy)
                
                // Convert the angle to a range from 0 to 360 (rather than having negative angles)
                let positiveAngle = angleRadians < 0.0 ? angleRadians + (2.0 * .pi) : angleRadians
                
                // Update slider progress value based on angle
                state.progress = positiveAngle / (2.0 * .pi)
                
                // Update angle
                state.rotationAngle = Angle(radians: positiveAngle)
                
                // Update time
                if(state.timeRemaining != Int((state.progress * 3600).rounded())) {
                    state.timeRemaining = Int((state.progress * 3600).rounded())
                    
                    if(state.timeRemaining.isMultiple(of: 5)) {
                        HapticManager.instance.impact(style: .medium)
                    }
                }
                
                return .none
            }
        }
    }
}
