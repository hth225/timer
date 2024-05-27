//
//  TimerView.swift
//  Timer
//
//  Created by Jason Hwang on 4/12/24.
//

import SwiftUI
import ComposableArchitecture
import Combine

struct TimerView: View {
    @State var store: StoreOf<TimerFeature>
    var bag = Set<AnyCancellable>()
    let ringDiameter = 300.0
    
    @State var point = CGPoint()
    
    init(store: StoreOf<TimerFeature>) {
        self.store = store
        
        // When application goes background
        NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)
            .sink { _ in
                store.send(.appDidEnterBackground)
            }.store(in: &bag)
        NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)
            .sink { _ in
                store.send(.appWillEnterForeground)
            }.store(in: &bag)
    }
    
    var body: some View {
        NavigationStack(path: $store.scope(state: \.path, action: \.path)){
            WithPerceptionTracking {
                VStack {
                    Text(store.pomodoroState != PomodoroState.disabled ? "Pomodoro" : "Timer")
                        .font(.headline)
                        .foregroundColor(.red)
                        .padding(.bottom, 24)
                    
                    if(store.pomodoroState != PomodoroState.disabled) {
                        Button(action: {
                            UNUserNotificationCenter.current().getPendingNotificationRequests(completionHandler: { results in
                                results.forEach { element in
                                    print("Pending id:\(element.identifier)")
                                }
                            })
                        }) {
                            Text("Completed: \(store.state.completedPomodoro)")
                                .font(.headline)
                                .foregroundColor(.red)
                                .padding(.bottom, 24)
                        }
                    }
                    ZStack {
                        Circle()
                            .stroke(Color(hue: 0.0, saturation: 0.0, brightness: 0.9), lineWidth: 20.0)
                            .overlay() {
                                Text(store.state.isTimerRunning ?
                                     "\(store.state.timeRemaining / 60):\(String(format: "%02d", (store.state.timeRemaining.remainderReportingOverflow(dividingBy: 60).partialValue)))"
                                     : "\((store.state.timeRemaining / 60))")
                                .font(.system(size: 78, weight: .bold, design:.rounded))
                                .animation(.linear(duration: 0.1), value: store.state.timeRemaining)
                            }
                        
                        Circle()
                            .trim(from: 0, to: store.state.progress)
                            .stroke(Color.red,
                                    style: StrokeStyle(lineWidth: 20.0, lineCap: .round)
                            )
                            .rotationEffect(Angle(degrees: -90))
                            .animation(.linear(duration: 0.05), value: store.state.progress)
                        
                        if(!store.state.isTimerRunning) {
                            Circle()
                                .fill(Color.white)
                                .shadow(radius: 3)
                                .frame(width: 21, height: 21)
                                .offset(y: -ringDiameter / 2.0)
                                .rotationEffect(store.state.rotationAngle)
                                .gesture(
                                    DragGesture(minimumDistance: 0.0)
                                        .onChanged() { value in
                                            store.send(.sliderChanged(value.location))
                                            point = value.location
                                        }
                                        .onEnded() { _ in
                                            store.send(.sliderEnded)
                                        }
                                )
                        }
                    }
                    .frame(width: ringDiameter, height: ringDiameter)
                }
                .padding(.vertical, 40)
                .padding()
                
                HStack {
                    // Pomodoro 이며, timer 작동중이면 일시정지 숨기기.
                    if(!(store.state.pomodoroState != PomodoroState.disabled && store.state.isTimerRunning)) {
                        Spacer()
                        Button(action: {
                            store.send(.pauseOrResumeTimer)
                        }) {
                            Image(systemName: store.isTimerRunning ? "pause.fill" : "play.fill")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .foregroundStyle(.red)
                                .frame(width: 50, height: 50)
                        }
                        .disabled(store.state.timeRemaining <= 0)
                    }
                    Spacer()
                    Button(action: {
                        store.send(.stopTimer)
                    }) {
                        Image(systemName: "stop.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .foregroundStyle(!store.state.isTimerRunning ? .gray :.red)
                            .frame(width: 50, height: 50)
                    }
                    .disabled(!store.isTimerRunning)
                    Spacer()
                    if(!store.isTimerRunning) {
                        Button(action: {
                            store.send(.navigateToSetting)
                        }) {
                            Image(systemName: "gearshape.fill")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .foregroundColor(.red)
                                .frame(width: 50, height: 50)
                        }
                        Spacer()
                    }
                }
            }
            .onAppear {
                store.send(.initTimer)
            }
        }destination: { store in
            switch store.case {
            case let .setting(store):
                SettingView(store: store)
            }
        }
    }
}

#Preview {
    TimerView(store: Store(initialState: TimerFeature.State(timeRemaining: 60000)){
        TimerFeature()
    })
}
