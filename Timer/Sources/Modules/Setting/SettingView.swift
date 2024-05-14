//
//  SettingView.swift
//  Timer
//
//  Created by Jason Hwang on 5/14/24.
//

import SwiftUI
import ComposableArchitecture


struct SettingView: View {
    let store: StoreOf<SettingFeature>
    
    var timeArray:[Int] = Array(1...30).map { $0 }
    var intervalArray:[Int] = Array(1...10).map { $0 }
    
    var body: some View {
        WithViewStore(self.store, observe: { $0 }) { viewStore in
            VStack {
                Form {
                    HStack {
                        Image(systemName: "timer")
                        Text("Pomodoro mode")
                        Spacer()
                        Toggle("", isOn: viewStore.binding(get: \.pomodoroActive, send: {.onPomodoroModeChanged($0)}))
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 4)
                    .tint(.red)
                    
                    Section("Pomodoro settings") {
                        VStack {
                            HStack {
                                Image(systemName: "cup.and.saucer")
                                Text("Short break time")
                                Spacer()
                                Picker("", selection: viewStore.binding(get: \.selectedShortBreak, send: { .onShortBreakChanged($0) })) {
                                    ForEach(timeArray, id: \.self) {
                                        Text("\($0)")
                                    }
                                }
                                .pickerStyle(.wheel)
                                .cornerRadius(15)
                                .frame(width: 80, height: 80)
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 4)
                            
                            HStack {
                                Image(systemName: "mug")
                                Text("Long break time")
                                Spacer()
                                Picker("", selection: viewStore.binding(get: \.selectedLongBreak, send: { .onLongBreakChanged($0)})) {
                                    ForEach(timeArray, id: \.self) {
                                        Text("\($0)")
                                    }
                                }
                                .pickerStyle(.wheel)
                                .cornerRadius(15)
                                .frame(width: 80, height: 80)
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 4)
                            
                            HStack {
                                Image(systemName: "gauge.with.needle")
                                Text("Long break interval")
                                Spacer()
                                Picker("Choose a color", selection: viewStore.binding(get: \.selectedInterval, send: { .onIntervalChanged($0)})) {
                                    ForEach(timeArray, id: \.self) {
                                        Text("\($0)")
                                    }
                                }
                                .pickerStyle(.wheel)
                                .cornerRadius(15)
                                .frame(width: 80, height: 80)
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 4)
                        }
                    }
                }
            }
        }.task {
            store.send(.setup)
        }
    }
}

#Preview {
    SettingView(store: Store(initialState: SettingFeature.State()){
        SettingFeature()
    })
}
