import SwiftUI

@main
struct ScreenCastApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}

struct RootView: View {
    @StateObject private var model = CallModel()
    @StateObject private var groups = GroupStore()
    @State private var showSettings = false

    var body: some View {
        Group {
            if model.inRoom {
                CallView(model: model)
            } else {
                HomeView(model: model, groups: groups, showSettings: $showSettings)
            }
        }
        .environment(\.layoutDirection, .rightToLeft)
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showSettings) {
            SettingsView()
                .environment(\.layoutDirection, .rightToLeft)
                .preferredColorScheme(.dark)
        }
        .alert(isPresented: Binding(
            get: { model.error != nil },
            set: { if !$0 { model.error = nil } }
        )) {
            Alert(title: Text("تنبيه"),
                  message: Text(model.error ?? ""),
                  dismissButton: .default(Text("تمام")))
        }
    }
}
