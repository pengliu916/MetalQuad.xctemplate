//___FILEHEADER___

import SwiftUI

@main
struct ___FILEBASENAMEASIDENTIFIER___: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
#if os(macOS)
                .onDisappear{NSApplication.shared.terminate(self)}
#else
                .onAppear{UIApplication.shared.isIdleTimerDisabled = true}
#endif
        }
#if os(macOS)
        .windowStyle(HiddenTitleBarWindowStyle())
#endif
    }
}
