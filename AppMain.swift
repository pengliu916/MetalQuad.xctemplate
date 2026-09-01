//___FILEHEADER___

import SwiftUI

@main
struct ___FILEBASENAMEASIDENTIFIER___: App {
    var body: some Scene {
#if os(macOS)
        Window("___PROJECTNAME___", id: "main") {
            content
        }
        .windowStyle(HiddenTitleBarWindowStyle())
#else
        WindowGroup {
            content
                .onAppear{UIApplication.shared.isIdleTimerDisabled = true}
        }
#endif
    }

    private var content: some View {
        ContentView()
            .preferredColorScheme(.dark)
    }
}
