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
        
        // current Pomodoro state
        var pomodoroState = PomodoroState.disabled
        // Completed pomodoro count
        var completedPomodoro = 0
    }
    
    enum Action {
        case initTimer
        case startTimer
        case pauseOrResumeTimer
        case stopTimer
        case tick
        case appDidEnterBackground
        case appWillEnterForeground
        case sliderChanged(CGPoint)
        case sliderEnded
        
        // pomodoro 를 위한 tick action
        case pomodoroTick
        
        case flipPomodoroState
    }
    
    
    var body: some Reducer<State, Action> {
        Reduce{ state, action in
            switch action {
            case .initTimer:
                state.progress = Double(state.timeRemaining) * Constants.secondToProgress
                // Positive angle 구해서 rotation angle 구하기
                state.rotationAngle = Angle(radians: state.progress * (2.0 * .pi))
                return .none
            case .startTimer:
                // timer 시작
                state.isTimerRunning = true
                
                // Local notification
                UNUserNotificationCenter.current().removeAllPendingTimers()
                
                if(state.pomodoroState == PomodoroState.active) {
                    state.pomodoroState = PomodoroState.focus
                    UNUserNotificationCenter.current().addPomodoroNotifications(focusTime: state.timeRemaining)
                    return .run { send in
                        for await _ in self.clock.timer(interval: .seconds(1)) {
                            await send(.pomodoroTick)
                        }
                    }.cancellable(id: "timer")
                } else {
                    UNUserNotificationCenter.current().addTimerNoti(id: UUID().uuidString, time: state.timeRemaining)
                    return .run { send in
                        for await _ in self.clock.timer(interval: .seconds(1)) {
                            await send(.tick)
                        }
                    }.cancellable(id: "timer")
                }
            case .pauseOrResumeTimer:
                // MARK : POMODORO MODE
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
                state.showAlert = true
                state.isTimerRunning = false
                state.timeRemaining = 0
                state.progress = 0.0
                state.rotationAngle = Angle(degrees: 0)
                // User defaults 도 초기화
                UserDefaultsHelper.time = 0
                UNUserNotificationCenter.current().removeAllPendingTimers()
                
                // Pomodoro state reset
                if(state.pomodoroState == PomodoroState.focus || state.pomodoroState == PomodoroState.rest) {
                    state.pomodoroState = PomodoroState.active
                }
                return .cancel(id: "timer")
            case .tick:
                if state.timeRemaining > 0 {
                    state.timeRemaining -= 1
                    state.progress -= 0.00028
                    state.rotationAngle -= Angle(degrees: 0.0948)
                    return .none
                } else {
                    // Timer end. Resetting indicator.
                    state.progress = 0.0
                    state.rotationAngle = Angle(degrees: 0)
                    // end sound
                    do {
                        try SoundManager.instance.playTimerEnd()
                    } catch(let error) {
                        print("Audio error :\(error)")
                    }
                    
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
                
                if(state.timeRemaining >= seconds) {
                    state.timeRemaining -= seconds
                } else {
                    state.timeRemaining = 0
                }
                
                return .none
            case let .sliderChanged(location):
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
                
                let currentTime = Int((state.progress * 3600))
                
                // Update time
                if(state.timeRemaining != (currentTime - currentTime.remainderReportingOverflow(dividingBy: 60).partialValue)) {
                    // 1분 이하의 숫자 지우기
                    state.timeRemaining = (currentTime - currentTime.remainderReportingOverflow(dividingBy: 60).partialValue)
//                    state.timeRemaining -= state.timeRemaining.remainderReportingOverflow(dividingBy: 60).partialValue
                    
                    // 5분(300초) 단위로 햅틱
                    if(state.timeRemaining.isMultiple(of: 300)) {
                        HapticManager.instance.impact(style: .medium)
                    }
                }
                
                return .none
            case .sliderEnded:
                // User defaults 에 저장
                UserDefaultsHelper.time = state.timeRemaining
                return .none
            case .pomodoroTick:
                if state.timeRemaining > 0 {
                    state.timeRemaining -= 1
                    state.progress -= 0.00028
                    state.rotationAngle -= Angle(degrees: 0.0948)
                    return .none
                } else {
                    // Timer end
                    state.showAlert = true
//                    state.isTimerRunning = false
                    state.progress = 0.0
                    state.rotationAngle = Angle(degrees: 0)
                    // end sound
                    do {
                        try SoundManager.instance.playTimerEnd()
                    } catch(let error) {
                        print("Audio error :\(error)")
                    }
                    
                    // prev : focus
                    // next : rest
                    if(state.pomodoroState == PomodoroState.focus) {
                        state.pomodoroState = PomodoroState.rest
                        // 5min rest time
                        state.timeRemaining = 300
                        
                        // reset UI
                        state.progress = Double(state.timeRemaining) * Constants.secondToProgress
                        // Positive angle 구해서 rotation angle 구하기
                        state.rotationAngle = Angle(radians: state.progress * (2.0 * .pi))
                        
                        return .none
                    }
                    // prev : Rest
                    // next : focus
                    else if(state.pomodoroState == PomodoroState.rest){
                        state.pomodoroState = PomodoroState.focus
                        // focus time from UserDefaults
                        state.timeRemaining = UserDefaultsHelper.time
                        
                        // reset UI
                        state.progress = Double(state.timeRemaining) * Constants.secondToProgress
                        // Positive angle 구해서 rotation angle 구하기
                        state.rotationAngle = Angle(radians: state.progress * (2.0 * .pi))
                        
                        return .none
                    } else {
                        return .cancel(id: "timer")
                    }
                }
            case .flipPomodoroState:
                if(state.pomodoroState == PomodoroState.disabled) {
                    state.pomodoroState = PomodoroState.active
                } else if(state.pomodoroState == PomodoroState.active) {
                    state.pomodoroState = PomodoroState.disabled
                }
                return .none
            }
        }
    }
}
