import SwiftUI
import ComposableArchitecture
import BackgroundTasks
import Combine

@main
struct TimerApp: App {
    
    var body: some Scene {
        WindowGroup {
            TimerView(store: Store(initialState: TimerFeature.State(timeRemaining: UserDefaultsHelper.time)){
                TimerFeature()
            })
            .task {
                // permission check
                if (!(await PermissionMananger.notiPermissionStatus())) {
                    try? await PermissionMananger.requestNotiPermission()
                }
            }
            .onAppear {
                
                // set default userDefault values
                UserDefaults.standard.register(defaults: [Constants.timeKey : 1500])
                UserDefaults.standard.register(defaults: [Constants.pomodoroRestTimeKey : 300])
                UserDefaults.standard.register(defaults: [Constants.pomodoroLongRestIntervalKey : 2])
                UserDefaults.standard.register(defaults: [Constants.pomodoroLongRestTimeKey : 900])
                
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
