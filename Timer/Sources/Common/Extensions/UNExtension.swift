//
//  UNExtension.swift
//  Timer
//
//  Created by Jason Hwang on 4/19/24.
//

import Foundation
import UserNotifications

extension UNUserNotificationCenter {
    func addNoti(id: String, time:Int, title: String, body: String) {
        // content 만들기
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        print("UUID:\(id), Time:\(time)")
        // trigger 만들기
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(time / 10), repeats: false)
        
        // request 만들기
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        
//        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
    }
    
    func addTimerNoti(id: String, time: Int) {
        self.addNoti(id: id, time: time, title: "Timer Completed", body: "\(Int(time/60)) Minutes")
    }
    
    func removeAllPendingTimers() {
        removeAllPendingNotificationRequests()
    }
    
    func addFocusNoti(id: String, time: Int) {
        self.addNoti(id: id, time: time, title: "Focus Session Completed", body: "\(Int(time/60)) Minutes")
    }
    
    func addRestNoti(restTime: Int, time: Int, index: Int) {
        self.addNoti(id: UUID().uuidString, time: time - restTime, title: "Focus Session Completed", body: "\(Int(time/60)) Minutes")
        
        self.addNoti(id: UUID().uuidString, time: time, title: "Rest Session Completed", body: "\(index) pomodoro completed")
    }
    
    func addPomodoroNotifications(focusTime: Int) {
        let interval = (UserDefaultsHelper.pomodoroLongRestInterval + 1)
        let longRestTime = UserDefaultsHelper.pomodoroLongRestTime
        let shortRestTime = UserDefaultsHelper.pomodoroRestTime
        
        var pomodoroNotiList: [Pomodoro] = Array(1...43).map { index in
            // 3의 배수 pomodoro 는 long rest.
            if(index % interval == 0) {
                return Pomodoro(id: index, focusTime: focusTime, restTime: longRestTime)
            } else {
                return Pomodoro(id: index, focusTime: focusTime, restTime: shortRestTime)
            }
        }
        
        // 한 세션의 총 시간
        let sessionTotalTime = pomodoroNotiList.filter {element in
            1..<(interval + 1) ~= element.id
        }.map { element in
            element.focusTime + element.restTime
        }.reduce(0, +)
        
        // 1개 pomodoro 총 시간(long rest X)
        let pomodoroTotalTime = pomodoroNotiList.first!.focusTime + pomodoroNotiList.first!.restTime
        
        
        // add notificaion to queue
        pomodoroNotiList.forEach { pomodoro in
            // interval 만큼 묶었을때
            // session = interval 만큼 묶인 단위
            
            
            // 현재까지 몇개의 long rest 가 있었는지
            let longRestCount = Int(pomodoro.id / interval)
        
            // 현재 뽀로도로까지 걸린 시간 (현재 podmodoro id * pomodoro time + 쉬는시간 두종류의 차 * 긴 휴식 카운트)
            let distance = (pomodoro.id) *  pomodoroTotalTime + (longRestTime - shortRestTime) * longRestCount
            
            // long rest pomodoro session
            // sessionIndex = 0 means it's the last session
//            if(pomodoro.id % interval == 0) {
//                
//                addRestNoti(id: "rest\(pomodoro.id)", time: , index: pomodoro.id)
//            }
            
//            self.addFocusNoti(id: UUID().uuidString, time: distance - pomodoro.restTime)
//            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(100)) {
//            }
            self.addRestNoti(restTime: pomodoro.restTime, time: distance, index: pomodoro.id)
        }
    }
}
