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
    let ringDiameter = 300.0
    
    @State var point = CGPoint()
    
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
            
//            Text("Location:\(point.x)")
//                .font(.title2)
//                .padding(.horizontal, 16)
//            
//            Text("Progress:\(store.state.progress)")
//                .font(.title2)
//                .padding(.horizontal, 16)
//            
//            
//            Text("Progress:\(store.state.rotationAngle.degrees)")
//                .font(.title2)
//                .padding(.horizontal, 16)
//            
//            Text("\(store.state.timeRemaining)")
            
//            Button(action: {
//                viewStore.send(.startTimer)
//            }) {
//                Image(systemName: "play.fill")
//                    .foregroundStyle(.red)
//                    .frame(width: 50, height: 50)
//            }
            HStack {
                Spacer()
                Button(action: {
                    viewStore.send(.pauseOrResumeTimer)
                }) {
                    Image(systemName: viewStore.state.isTimerRunning ? "pause.fill" : "play.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .foregroundStyle(.red)
                        .frame(width: 50, height: 50)
                }
                .disabled(store.state.timeRemaining <= 0)
                Spacer()
                Button(action: {
                    viewStore.send(.stopTimer)
                }) {
                    Image(systemName: "stop.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .foregroundStyle(.red)
                        .frame(width: 50, height: 50)
                }
                .disabled(!store.state.isTimerRunning)
                Spacer()
            }
        }
        .task {
            store.send(.initTimer)
            UNUserNotificationCenter.current().addNoti(id: UUID().uuidString, time: 20)
        }
    }
}

#Preview {
    TimerView(store: Store(initialState: TimerFeature.State(timeRemaining: 60000)){
        TimerFeature()
    })
}
