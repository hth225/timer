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
    
    @Reducer(state: .equatable)
    enum Path {
        case setting(SettingFeature)
    }
    
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
        var appDidEnterBackground: Bool = false
        
        // Circle slider progress. (max: 1.0)
        var progress = 0.0
        // Circle slider rotation angle
        var rotationAngle = Angle(degrees: 0)
        
        // current Pomodoro state
        var pomodoroState = PomodoroState.disabled
        // Completed pomodoro count
        var completedPomodoro = 0
        
        var time: Int = 0
        var focusTime: Int = 0
        var restTime: Int = 0
        var longRestTime: Int = 0
        var pomodoroInterval = 0
        
        // navigation
        var path = StackState<Path.State>()
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
        
        // navigation
        case navigateToSetting
        case path(StackAction<Path.State, Path.Action>)
    }
    
    
    var body: some Reducer<State, Action> {
        Reduce{ state, action in
            switch action {
            case .initTimer:
                state.time = UserDefaultsHelper.time
                state.pomodoroState = UserDefaultsHelper.pomodoroState
                state.focusTime = UserDefaultsHelper.pomodoroFocusTime
                state.restTime = UserDefaultsHelper.pomodoroRestTime
                state.longRestTime = UserDefaultsHelper.pomodoroLongRestTime
                state.pomodoroInterval = UserDefaultsHelper.pomodoroLongRestInterval
                
                state.timeRemaining = state.pomodoroState != PomodoroState.disabled ? state.focusTime : state.time
                
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
                     
                    state.focusTime = UserDefaultsHelper.pomodoroFocusTime
                    state.restTime = UserDefaultsHelper.pomodoroRestTime
                    state.longRestTime = UserDefaultsHelper.pomodoroLongRestTime
                    state.pomodoroInterval = UserDefaultsHelper.pomodoroLongRestInterval
                    
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
                    
                    if(!state.appDidEnterBackground) {
                        // end sound
                        do {
                            try SoundManager.instance.playTimerEnd()
                        } catch(let error) {
                            print("Audio error :\(error)")
                        }
                        
                    }
                    
                    return .cancel(id: "timer")
                }
            case .appDidEnterBackground:
                state.appDidEnterBackgroundDate = Date()
                state.appDidEnterBackground = true
                if(state.pomodoroState != PomodoroState.disabled) {
                    BackgroundTaskHelper().scheduleAppRefresh()
                }
                return .none
            case .appWillEnterForeground:
                state.appDidEnterBackground = false
                guard let previousDate = state.appDidEnterBackgroundDate else { return .none }
                let calendar = Calendar.current
                let difference = calendar.dateComponents([.second], from: previousDate, to: Date())
                var seconds = difference.second!
                //                var seconds = 2000
                // *interval* 만큼의 단위가 얼마나 지났는지
                var intervalCount = 0
                print("Time diff:\(seconds)")
                
                if(state.timeRemaining >= seconds) {
                    state.timeRemaining -= seconds
                    return .none
                    
                } else {
                    // pomoro on
                    if(state.pomodoroState != PomodoroState.disabled && state.pomodoroState != PomodoroState.active) {
                        
                        // interval 만큼의 세션 총 시간
                        let totalTime = (state.focusTime + state.restTime) * state.pomodoroInterval + (state.longRestTime - state.restTime)
                        let withoutLongrestTotal = (state.focusTime + state.restTime) * state.pomodoroInterval
                        print("Interval total time: \(totalTime). focus\(state.focusTime) rest\(state.restTime) interval\(state.pomodoroInterval) longrest\(state.longRestTime)")
                        
                        // interval 만큼의 시간이 지났는지 여부 확인. 지났다면 시간 계산이 다름.
                        // 앞쪽에서 큰 단위의 시간 절삭하기.
                        if(totalTime <= seconds) {
                            let count = Int(seconds / totalTime)
                            seconds -= count * totalTime
                            state.completedPomodoro += count * state.pomodoroInterval
                            
                            print("Over interval")
                            print("Session count:\(count)")
                            print("remain count:\(seconds)")
                            
                            intervalCount += count
                            print("Interval count:\(intervalCount)")
                        }
                        
                        // interval 만큼의 시간이 지난게 아니면 longRest 제외한 시간이 지났는지 확인 해야함.
                        
                        // long rest 까지 도달하지 못함. interval 안쪽.
                        if(withoutLongrestTotal >= seconds) {
                            let count = Int(seconds / (state.focusTime + state.restTime))
                            // 남은 시간
                            let remain = seconds - ((state.focusTime + state.restTime) * count)
                            state.completedPomodoro += count
                            
                            print("Under interval")
                            print("count:\(count)")
                            print("remain count:\(remain)")
                            
                            if(remain <= state.focusTime) {
                                print("FocusSession. time left:\(state.focusTime - remain)")
                                state.timeRemaining = state.focusTime - remain
                                state.pomodoroState = PomodoroState.focus
                            } else {
                                print("Rest session. time left:\(state.restTime - (remain - state.focusTime))")
                                state.timeRemaining = state.restTime - (remain - state.focusTime)
                                state.pomodoroState = PomodoroState.rest
                            }
                        } else {
                            // long rest 까지 도달함. interval 안쪽.
                            let count = state.pomodoroInterval
                            let remain = state.longRestTime - (seconds % ((state.focusTime + state.restTime) * count))
                            state.completedPomodoro += count
                            print("Under interval. Over long rest")
                            print("count:\(count)")
                            print("remain count:\(remain)")
                            
                            if(remain <= state.focusTime) {
                                print("FocusSession. time left:\(state.focusTime - remain)")
                                state.timeRemaining = state.focusTime - remain
                                state.pomodoroState = PomodoroState.focus
                            } else {
                                print("Rest session. time left:\(state.restTime - (remain - state.focusTime))")
                                state.timeRemaining = state.restTime - (remain - state.focusTime)
                                state.pomodoroState = PomodoroState.rest
                            }
                        }
                    } else {
                        state.timeRemaining = 0
                        
                    }
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
                // Pomodoro 모드와 일반 타이머 모드는 따로 저장한다.
                if(state.pomodoroState != PomodoroState.disabled) {
                    UserDefaultsHelper.pomodoroFocusTime = state.timeRemaining
                } else {
                    UserDefaultsHelper.time = state.timeRemaining
                }
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
                    state.progress = 0.0
                    state.rotationAngle = Angle(degrees: 0)
                    state.completedPomodoro += 1
                    
                    if(!state.appDidEnterBackground) {
                        // end sound
                        do {
                            try SoundManager.instance.playTimerEnd()
                        } catch(let error) {
                            print("Audio error :\(error)")
                        }
                    }
                    
                    // prev : focus
                    // next : rest
                    if(state.pomodoroState == PomodoroState.focus) {
                        state.pomodoroState = PomodoroState.rest
                        
                        if(state.completedPomodoro % state.pomodoroInterval == 0) {
                            // long rest time
                            state.timeRemaining = state.longRestTime
                        } else {
                            // rest time
                            state.timeRemaining = state.restTime
                        }
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
                        state.timeRemaining = state.focusTime
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
                UserDefaultsHelper.pomodoroState = state.pomodoroState
                return .none
            case .navigateToSetting:
                state.path.append(.setting(SettingFeature.State()))
                return .none
            case let .path(action):
                switch action {
                default:
                    return .none
                }
            }
        }
        .forEach(\.path, action: \.path)
    }
}
