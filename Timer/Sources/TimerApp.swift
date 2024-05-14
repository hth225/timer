import SwiftUI
import ComposableArchitecture
import BackgroundTasks
import Combine

@main
struct TimerApp: App {
    
    var body: some Scene {
        WindowGroup {
//            TimerView(store: Store(initialState: TimerFeature.State(timeRemaining: UserDefaultsHelper.time)){
//                TimerFeature()
//            })
            SettingView(store: Store(initialState: SettingFeature.State()){
                SettingFeature()
            })
            .task {
                // permission check
                if (!(await PermissionMananger.notiPermissionStatus())) {
                    try? await PermissionMananger.requestNotiPermission()
                }
            }
            .onAppear {
                
                // set default userDefault values
                UserDefaults.standard.register(defaults: [
                    Constants.timeKey : 1500,
                    Constants.pomodoroFocusTimeKey : 1500,
                    Constants.pomodoroRestTimeKey : 300,
                    Constants.pomodoroLongRestIntervalKey : 3,
                    Constants.pomodoroLongRestTimeKey : 900,
                ])
                
                BGTaskScheduler.shared.register(forTaskWithIdentifier: Constants.backgroundTaskIdentifier, using: nil) { task in
                    self.handleAppRefresh(task: task as! BGAppRefreshTask)
                }
            }
        }
    }
    
    func handleAppRefresh(task: BGAppRefreshTask) {
        // Schedule a new refresh task.
        BackgroundTaskHelper().scheduleAppRefresh()
        
        
        // Create an operation that performs the main part of the background task.
        DispatchQueue.global().async {
            UNUserNotificationCenter.current().addNextPomodoroOnBackground(10)
        }
        
        // Provide the background task with an expiration handler that cancels the operation.
        //       task.expirationHandler = {
        //          operation.cancel()
        //       }
        
        
        // Inform the system that the background task is complete
        // when the operation completes.
        
        task.setTaskCompleted(success: true)
        
    }
}
