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
            }
        }
    }
}
