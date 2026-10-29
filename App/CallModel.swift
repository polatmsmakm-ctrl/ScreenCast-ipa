import SwiftUI
import UIKit

final class CallModel: ObservableObject {
    enum Kind { case none, big, sub }

    struct Peer: Identifiable, Equatable {
        let id: String
        var kind: Kind = .none
    }

    @Published var inRoom = false
    @Published var connecting = false
    @Published var muted = false
    @Published var sharing = false
    @Published var peers: [Peer] = []
    @Published var error: String?
    @Published var room = ""
    @Published var quality = 1

    private let engine = CallEngine.shared

    init() {
        engine.onEntered = { [weak self] result in
            guard let self = self else { return }
            self.connecting = false
            if result < 0 {
                self.error = "تعذّر الدخول (كود \(result)). تأكد من SDKAppID والمفتاح السري في الإعدادات."
                self.engine.exitRoom()
                self.inRoom = false
            } else {
                self.inRoom = true
            }
        }
        engine.onUserJoined = { [weak self] uid in self?.ensurePeer(uid) }
        engine.onUserLeft = { [weak self] uid in
            self?.peers.removeAll { $0.id == uid }
        }
        engine.onVideo = { [weak self] uid, isSub, available in
            guard let self = self else { return }
            self.ensurePeer(uid)
            guard let i = self.peers.firstIndex(where: { $0.id == uid }) else { return }
            let kind: Kind = isSub ? .sub : .big
            if available {
                self.peers[i].kind = kind
            } else if self.peers[i].kind == kind {
                self.peers[i].kind = .none
            }
        }
        engine.onScreenState = { [weak self] on in self?.sharing = on }
        engine.onError = { [weak self] msg in self?.error = msg }
    }

    private func ensurePeer(_ uid: String) {
        if !peers.contains(where: { $0.id == uid }) {
            peers.append(Peer(id: uid))
        }
    }

    func join(name: String, room: String) {
        let d = UserDefaults.standard
        let appIdText = (d.string(forKey: "sdkAppId") ?? "").trimmingCharacters(in: .whitespaces)
        let key = (d.string(forKey: "secretKey") ?? "").trimmingCharacters(in: .whitespaces)
        guard let appId = UInt32(appIdText), !key.isEmpty else {
            error = "افتح الإعدادات (⚙️) وحط SDKAppID والمفتاح السري من حساب تينسنت."
            return
        }
        let n = name.trimmingCharacters(in: .whitespaces)
        let r = room.trimmingCharacters(in: .whitespaces)
        guard !n.isEmpty, !r.isEmpty else {
            error = "اكتب اسمك واسم الغرفة."
            return
        }
        self.room = r
        connecting = true
        peers = []
        muted = false
        UIApplication.shared.isIdleTimerDisabled = true
        engine.enter(withSdkAppId: appId, secretKey: key, userId: n, room: r)
    }

    func leave() {
        engine.exitRoom()
        inRoom = false
        connecting = false
        sharing = false
        peers = []
        UIApplication.shared.isIdleTimerDisabled = false
    }

    func toggleMute() {
        muted.toggle()
        engine.setMuted(muted)
    }

    func startShare(picker: PickerBox) {
        engine.startScreenShare(quality)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            picker.trigger()
        }
    }

    func stopShare() {
        engine.stopScreenShare()
        sharing = false
    }
}
