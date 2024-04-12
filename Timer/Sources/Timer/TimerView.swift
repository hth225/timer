//
//  TimerView.swift
//  Timer
//
//  Created by Jason Hwang on 4/12/24.
//

import SwiftUI
import ComposableArchitecture

struct TimerView: View {
    let store: Store<TimerFeature.State, TimerFeature.Action>
    @ObservedObject private var viewStore: ViewStore<TimerFeature.State, TimerFeature.Action>
    
    init(store: Store<TimerFeature.State, TimerFeature.Action>) {
        self.store = store
        self.viewStore = ViewStore(store, observe: { $0 })
    }
    
    var body: some View {
        VStack {
            Text("\(viewStore.state.timeRemaining)")
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

#Preview {
    TimerView(store: Store(initialState: TimerFeature.State(timeRemaining: 60000)){
        TimerFeature()
    })
}
