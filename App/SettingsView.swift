import SwiftUI

struct SettingsView: View {
    @Environment(\.presentationMode) private var presentation
    @AppStorage("sdkAppId") private var sdkAppId = ""
    @AppStorage("secretKey") private var secretKey = ""

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("حساب تينسنت (TRTC)"),
                        footer: Text("من لوحة Tencent Cloud ← TRTC ← Application Management ← تطبيقك. انسخ SDKAppID والمفتاح السري (SDKSecretKey). كل أصدقائك لازم يحطون نفس القيم.")) {
                    TextField("SDKAppID", text: $sdkAppId)
                        .keyboardType(.numberPad)
                    SecureField("SDKSecretKey", text: $secretKey)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                }
            }
            .navigationBarTitle("الإعدادات", displayMode: .inline)
            .navigationBarItems(trailing: Button("تم") { presentation.wrappedValue.dismiss() })
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}
