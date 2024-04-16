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
    let store: Store<TimerFeature.State, TimerFeature.Action>
    @ObservedObject private var viewStore: ViewStore<TimerFeature.State, TimerFeature.Action>
    var bag = Set<AnyCancellable>()
    
    init(store: Store<TimerFeature.State, TimerFeature.Action>) {
        self.store = store
        self.viewStore = ViewStore(store, observe: { $0 })
        
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
        WithPerceptionTracking {
            VStack {
                Text("\(store.state.timeRemaining)")
                Button(action: {
                    viewStore.send(.startTimer)
                }) {
                    Text("Start Timer")
                        .font(.headline)
                }
                Button(action: {
                    viewStore.send(.pauseOrResumeTimer)
                }) {
                    Text(viewStore.state.isTimerRunning ? "Pause" : "Resume")
                        .font(.headline)
                }
                Button(action: {
                    viewStore.send(.stopTimer)
                }) {
                    Text("Stop timer")
                        .font(.headline)
                }
            }
        }
    }
}

#Preview {
    TimerView(store: Store(initialState: TimerFeature.State(timeRemaining: 60000)){
        TimerFeature()
    })
}
