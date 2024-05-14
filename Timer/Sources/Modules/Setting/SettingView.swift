//
//  SettingView.swift
//  Timer
//
//  Created by Jason Hwang on 5/14/24.
//

import SwiftUI

struct SettingView: View {
    @State private var pomodoroActive = false
    @State private var selectedShortBreak = 5
    @State private var selectedLongBreak = 15
    @State private var selectedInterval = 3
    
    var timeArray:[Int] = Array(1...30).map { $0 }
    var intervalArray:[Int] = Array(1...10).map { $0 }
    
    var body: some View {
        VStack {
            Form {
                HStack {
                    Image(systemName: "timer")
                    Text("Pomodoro mode")
                    Spacer()
                    Toggle("", isOn: $pomodoroActive)
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
                            Picker("", selection: $selectedShortBreak) {
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
                            Picker("", selection: $selectedLongBreak) {
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
                            Picker("Choose a color", selection: $selectedInterval) {
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
    }
}

#Preview {
    SettingView()
}
