import SwiftUI
import ComposableArchitecture

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
                
                // set default userDefault values
                UserDefaults.standard.register(defaults: [Constants.timeKey : 1500])
                UserDefaults.standard.register(defaults: [Constants.pomodoroRestTimeKey : 300])
                UserDefaults.standard.register(defaults: [Constants.pomodoroLongRestIntervalKey : 2])
                UserDefaults.standard.register(defaults: [Constants.pomodoroLongRestTimeKey : 900])
            }
        }
    }
}
