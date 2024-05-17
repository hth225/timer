import SwiftUI
import ComposableArchitecture
import BackgroundTasks
import Combine


// no changes in your AppDelegate class
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        
        BGTaskScheduler.shared.register(forTaskWithIdentifier: Constants.backgroundTaskIdentifier, using: nil) { task in
            self.handleAppRefresh(task: task as! BGAppRefreshTask)
        }
        
        return true
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

@main
struct TimerApp: App {
    
    init() {
        
    }
    
    // inject into SwiftUI life-cycle via adaptor !!!
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            TimerView(store: Store(initialState: TimerFeature.State()){
                TimerFeature()
            })
            .task {
                
                // set default userDefault values
                UserDefaults.standard.register(defaults: [
                    Constants.timeKey : 1500,
                    Constants.pomodoroFocusTimeKey : 1500,
                    Constants.pomodoroRestTimeKey : 300,
                    Constants.pomodoroLongRestIntervalKey : 3,
                    Constants.pomodoroLongRestTimeKey : 900,
                ])
                
                // permission check
                if (!(await PermissionMananger.notiPermissionStatus())) {
                    try? await PermissionMananger.requestNotiPermission()
                }
            }
        }
    }
}
