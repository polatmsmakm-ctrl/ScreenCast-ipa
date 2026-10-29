import SwiftUI
import ReplayKit

/// يمسك بنافذة اختيار البث حق النظام عشان نضغطها برمجياً من زرنا.
final class PickerBox {
    weak var picker: RPSystemBroadcastPickerView?

    func trigger() {
        guard let picker = picker else { return }
        for sub in picker.subviews {
            if let button = sub as? UIButton {
                button.sendActions(for: .touchUpInside)
                return
            }
        }
    }
}

struct BroadcastPicker: UIViewRepresentable {
    let box: PickerBox

    func makeUIView(context: Context) -> RPSystemBroadcastPickerView {
        let v = RPSystemBroadcastPickerView(frame: CGRect(x: 0, y: 0, width: 44, height: 44))
        v.showsMicrophoneButton = false
        // نقرأ معرّف الإضافة من داخل التطبيق نفسه (يتغير لو Sideloadly غيّر الـ Bundle ID)
        if let plugins = Bundle.main.builtInPlugInsURL,
           let items = try? FileManager.default.contentsOfDirectory(at: plugins, includingPropertiesForKeys: nil),
           let appex = items.first(where: { $0.pathExtension == "appex" }),
           let bundle = Bundle(url: appex) {
            v.preferredExtension = bundle.bundleIdentifier
        }
        box.picker = v
        return v
    }

    func updateUIView(_ uiView: RPSystemBroadcastPickerView, context: Context) {}
}
