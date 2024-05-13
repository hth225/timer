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
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(time / 10), repeats: false)
        
        // request 만들기
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
    }
    
    func addPomodoroNoti(focus: PomodoroNotiInfo, rest: PomodoroNotiInfo) {
        let focusUUID = UUID().uuidString
        let restUUID = UUID().uuidString
        
        // content 만들기
        let focusContent = UNMutableNotificationContent()
        focusContent.title = focus.title
        focusContent.body = focus.body
        focusContent.sound = .default
        
        // content 만들기
        let restContent = UNMutableNotificationContent()
        restContent.title = rest.title
        restContent.body = rest.body
        restContent.sound = .default
        
        // trigger 만들기
        let focusTrigger = UNCalendarNotificationTrigger(dateMatching: focus.date, repeats: false)
        
        
        let restTrigger = UNCalendarNotificationTrigger(dateMatching: rest.date, repeats: false)
        
        // request 만들기
        let focusRequest = UNNotificationRequest(identifier: focusUUID, content: focusContent, trigger: focusTrigger)
        
        let restRequest = UNNotificationRequest(identifier: restUUID, content: restContent, trigger: restTrigger)
        
        // permission check
        self.requestAuthorization(options: [.alert, .sound, .badge]) { result, error in
            if(error == nil && result) {
                self.add(focusRequest) { error in
                    if(error != nil) {
                        print("Notification add Error:\(String(describing: error))")
                    } else {
                        print("F Queued:\(focus.date)\nUUID:\(focusUUID)")
                    }
                }
                
                self.add(restRequest) { error in
                    if(error != nil) {
                        print("Notification add Error:\(String(describing: error))")
                    } else {
                        print("R Queued:\(rest.date)\nUUID:\(restUUID)")
                    }
                }
            } else {
                if(error != nil) {
                    print("Error occurred during Notification request: \(String(describing: error))")
                } else {
                    print("Notification permission denied")
                }
            }
        }
    }
    
    func addTimerNoti(id: String, time: Int) {
        self.addNoti(id: id, time: time, title: "Timer Completed", body: "\(Int(time/60)) Minutes")
    }
    
    func removeAllPendingTimers() {
        removeAllPendingNotificationRequests()
        // clear Userdefaults info
        UserDefaultsHelper.pomodoroLatestNotiDate = nil
    }
    
    func addPomodoroNotifications(focusTime: Int) {
        let interval = (UserDefaultsHelper.pomodoroLongRestInterval + 1)
        let longRestTime = UserDefaultsHelper.pomodoroLongRestTime
        let shortRestTime = UserDefaultsHelper.pomodoroRestTime
        
        // 로컬노티는 128개가 최대갯수 제한..
        let pomodoroNotiList: [Pomodoro] = Array(1...interval).map { index in
            // 3의 배수 pomodoro 는 long rest.
            if(index % interval == 0) {
                return Pomodoro(id: index, focusTime: focusTime, restTime: longRestTime)
            } else {
                return Pomodoro(id: index, focusTime: focusTime, restTime: shortRestTime)
            }
        }
        
        // 1개 pomodoro 총 시간(long rest X)
        let pomodoroTotalTime = pomodoroNotiList.first!.focusTime + pomodoroNotiList.first!.restTime
        
        let calendar = Calendar.current
        let date = Date() // Current date
        
        var latestDateComponent = calendar.date(byAdding: DateComponents(second: focusTime), to: date)
        
        // add notificaion to queue
        pomodoroNotiList.forEach { pomodoro in
            // interval 만큼 묶었을때
            // session = interval 만큼 묶인 단위
            
            // 현재까지 몇개의 long rest 가 있었는지
            let longRestCount = Int(pomodoro.id / interval)
            
            // 현재 뽀로도로까지 걸린 시간 (현재 podmodoro id * pomodoro time + 쉬는시간 두종류의 차 * 긴 휴식 카운트)
            let distance = (pomodoro.id) *  pomodoroTotalTime + (longRestTime - shortRestTime) * longRestCount
            
            let focusDate = latestDateComponent!.addingTimeInterval(TimeInterval(focusTime))
            let restDate: Date =
                pomodoro.id % interval == 0 ? focusDate.addingTimeInterval(TimeInterval(longRestTime)) : focusDate.addingTimeInterval(TimeInterval(shortRestTime))
            
            let focusDateComponent = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: focusDate)
            let restDateComponent = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: restDate)
            
            DispatchQueue.main.async {
                                self.addPomodoroNoti(focus: PomodoroNotiInfo(pomodoroID: pomodoro.id, date: focusDateComponent, title: "Focus Session Completed", body: "\(Int((distance-pomodoro.restTime)/60)) Minutes"), rest: PomodoroNotiInfo(pomodoroID: pomodoro.id, date: restDateComponent, title: "Rest Session Completed", body: "\(pomodoro.id) pomodoro completed"))
            }
            
            // Update latest queued date
            latestDateComponent = restDate
        }
        
        UserDefaultsHelper.pomodoroLatestAddedIndex = interval
        UserDefaultsHelper.pomodoroLatestNotiDate = latestDateComponent
        
//        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
//            self.getPendingNotificationRequests(completionHandler: { results in
//                results.forEach { element in
//                    print("Pending id:\(element.identifier)")
//                }
//            })
//            
//        }
    }
    func addNextPomodoroOnBackground(_ amount: Int?) {
        let interval = (UserDefaultsHelper.pomodoroLongRestInterval + 1)
        let longRestTime = UserDefaultsHelper.pomodoroLongRestTime
        let shortRestTime = UserDefaultsHelper.pomodoroRestTime
        let focusTime = UserDefaultsHelper.time
        var latestNotiDate = UserDefaultsHelper.pomodoroLatestNotiDate ?? Date()
        let latestIndex = UserDefaultsHelper.pomodoroLatestAddedIndex
        
        // 마지막 index 에서 10개(or amount) 더 생성
        let pomodoroNotiList: [Pomodoro] = Array((latestIndex + 1)...(latestIndex + (amount ?? 11))).map { index in
            // 3의 배수 pomodoro 는 long rest.
            if(index % interval == 0) {
                return Pomodoro(id: index, focusTime: focusTime, restTime: longRestTime)
            } else {
                return Pomodoro(id: index, focusTime: focusTime, restTime: shortRestTime)
            }
        }
        
        // 1개 pomodoro 총 시간(long rest X)
        let pomodoroTotalTime = pomodoroNotiList.first!.focusTime + pomodoroNotiList.first!.restTime
        
        let calendar = Calendar.current
        
        // add notificaion to queue
        pomodoroNotiList.forEach { pomodoro in
            // interval 만큼 묶었을때
            // session = interval 만큼 묶인 단위
            
            // 현재까지 몇개의 long rest 가 있었는지
            let longRestCount = Int(pomodoro.id / interval)
            
            // 현재 뽀로도로까지 걸린 시간 (현재 podmodoro id * pomodoro time + 쉬는시간 두종류의 차 * 긴 휴식 카운트)
            let distance = (pomodoro.id) *  pomodoroTotalTime + (longRestTime - shortRestTime) * longRestCount
            
            let focusDate = latestNotiDate.addingTimeInterval(TimeInterval(focusTime))
            let restDate: Date =
                pomodoro.id % interval == 0 ? focusDate.addingTimeInterval(TimeInterval(longRestTime)) : focusDate.addingTimeInterval(TimeInterval(shortRestTime))
            
            let focusDateComponent = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: focusDate)
            let restDateComponent = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: restDate)
            
            
            self.addPomodoroNoti(focus: PomodoroNotiInfo(pomodoroID: pomodoro.id, date: focusDateComponent, title: "Focus Session Completed", body: "\(Int((distance-pomodoro.restTime)/60)) Minutes"), rest: PomodoroNotiInfo(pomodoroID: pomodoro.id, date: restDateComponent, title: "Rest Session Completed", body: "\(pomodoro.id) pomodoro completed"))
            
            print("Backgroudn noti queued")
            
            latestNotiDate = restDate
        }
        
        // Update latest queued date
        UserDefaultsHelper.pomodoroLatestAddedIndex = (latestIndex + (amount ?? 11))
        UserDefaultsHelper.pomodoroLatestNotiDate = latestNotiDate
    }
}
