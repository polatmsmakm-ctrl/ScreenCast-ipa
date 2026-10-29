import SwiftUI

struct SettingsView: View {
    @Environment(\.presentationMode) private var presentation
    @AppStorage("lkURL") private var url = ""
    @AppStorage("lkKey") private var key = ""
    @AppStorage("lkSecret") private var secret = ""
    @AppStorage("quality") private var quality = 1

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("خادم LiveKit"),
                        footer: Text("من cloud.livekit.io ← مشروعك ← Settings ← Keys. انسخ الرابط (wss://...) والمفتاح والسر. كل أصدقائك لازم يحطون نفس القيم.")) {
                    TextField("wss://your-project.livekit.cloud", text: $url)
                        .keyboardType(.URL)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                    TextField("API Key", text: $key)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                    SecureField("API Secret", text: $secret)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                }

                Section(header: Text("جودة بث شاشتك"),
                        footer: Text("تتغير من الدخول القادم للغرفة. الجودة القصوى تبث بدقة شاشة الايباد الأصلية (حتى 4K) و30 إطار.")) {
                    Picker("الجودة", selection: $quality) {
                        Text("أقصى جودة (30 إطار)").tag(1)
                        Text("نص واضح (15 إطار)").tag(2)
                        Text("متوازن 1080p").tag(0)
                    }
                    .pickerStyle(InlinePickerStyle())
                }
            }
            .navigationBarTitle("الإعدادات", displayMode: .inline)
            .navigationBarItems(trailing: Button("تم") { presentation.wrappedValue.dismiss() })
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}
