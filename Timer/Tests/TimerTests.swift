import Foundation
import SwiftUI
import XCTest
import ComposableArchitecture
@testable import Timer

final class TimerTests: XCTestCase {
    // Define the initial state, reducer, and environment if needed.
    func test_twoPlusTwo_isFour() {
        XCTAssertEqual(2+2, 4)
    }
    
    @MainActor
    func testAppWillEnterForeground_Non_pomodoro() async {
        // Create the test store
        let store = TestStore(
            initialState: TimerFeature.State(timeRemaining: 3500,appDidEnterBackgroundDate: Calendar.current.date(byAdding: .second, value: -2000, to: Date()))) {
            TimerFeature()
        }
        
        await store.send(.appWillEnterForeground) {
            $0.appDidEnterBackground = false
            $0.timeRemaining = 1500
        }
    }
    
    @MainActor
    func testAppWillEnterForeground_Pomodoro() async {
        // Create the test store
        let store = TestStore(
            initialState: TimerFeature.State(timeRemaining: 1500,
                                             appDidEnterBackgroundDate: Calendar.current.date(byAdding: .second, value: -2000, to: Date()), pomodoroState: PomodoroState.focus, completedPomodoro: 2, focusTime: 1500,
                                             restTime: 300,
                                             longRestTime: 900,
                                             pomodoroInterval: 3)) {
            TimerFeature()
        }
        
        await store.send(.appWillEnterForeground) {
            $0.appDidEnterBackground = false
            $0.timeRemaining = 1300
            $0.completedPomodoro = 3
            $0.pomodoroState = PomodoroState.focus
        }
    }
    
    @MainActor
    func testTimer() async {
        let clock = TestClock()
        
        let store = TestStore(initialState: TimerFeature.State(
            timeRemaining: 1500)) {
                TimerFeature()
            } withDependencies: {
                $0.continuousClock = clock
            }
        
        await store.send(.startTimer) {
            $0.isTimerRunning = true
        }
        await clock.advance(by: .seconds(1))
        await store.receive(\.tick) {
            $0.timeRemaining = 1499
            $0.progress = -0.00028
            $0.rotationAngle = Angle(degrees: -0.0948)
            
        }
        await store.send(.stopTimer) {
            $0.isTimerRunning = false
            $0.showAlert = true
            $0.timeRemaining = 0
            $0.progress = 0.0
            $0.rotationAngle = Angle(radians: 0.0)
            
        }
    }
}
