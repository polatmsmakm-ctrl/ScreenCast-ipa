import SwiftUI

struct RemoteVideoView: UIViewRepresentable {
    let userId: String
    let isSub: Bool

    final class Coordinator {
        let userId: String
        let isSub: Bool
        init(userId: String, isSub: Bool) {
            self.userId = userId
            self.isSub = isSub
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(userId: userId, isSub: isSub)
    }

    func makeUIView(context: Context) -> UIView {
        let v = UIView()
        v.backgroundColor = .black
        CallEngine.shared.showRemote(userId, isSub: isSub, in: v)
        return v
    }

    func updateUIView(_ uiView: UIView, context: Context) {}

    static func dismantleUIView(_ uiView: UIView, coordinator: Coordinator) {
        CallEngine.shared.hideRemote(coordinator.userId, isSub: coordinator.isSub)
    }
}
