import SwiftUI
import UIKit
import LiveKit

final class RoomObserver: NSObject, RoomDelegate, @unchecked Sendable {
    var onChange: (@Sendable () -> Void)?
    var onDisconnect: (@Sendable (String?) -> Void)?

    func room(_ room: Room, participantDidConnect participant: RemoteParticipant) { onChange?() }
    func room(_ room: Room, participantDidDisconnect participant: RemoteParticipant) { onChange?() }
    func room(_ room: Room, participant: RemoteParticipant, didSubscribeTrack publication: RemoteTrackPublication) { onChange?() }
    func room(_ room: Room, participant: RemoteParticipant, didUnsubscribeTrack publication: RemoteTrackPublication) { onChange?() }
    func room(_ room: Room, participant: RemoteParticipant, didUnpublishTrack publication: RemoteTrackPublication) { onChange?() }
    func room(_ room: Room, participant: LocalParticipant, didPublishTrack publication: LocalTrackPublication) { onChange?() }
    func room(_ room: Room, participant: LocalParticipant, didUnpublishTrack publication: LocalTrackPublication) { onChange?() }
    func room(_ room: Room, didUpdateSpeakingParticipants participants: [Participant]) { onChange?() }
    func room(_ room: Room, didDisconnectWithError error: LiveKitError?) {
        onDisconnect?(error.map { String(describing: $0) })
    }
}

@MainActor
final class CallModel: ObservableObject {
    struct Peer: Identifiable {
        let id: String
        var name: String
        var screen: VideoTrack?
        var screenKey: String
        var speaking: Bool
    }

    @Published var inRoom = false
    @Published var connecting = false
    @Published var muted = false
    @Published var sharing = false
    @Published var meSpeaking = false
    @Published var peers: [Peer] = []
    @Published var error: String?
    @Published var roomTitle = ""
    @Published var mutedPeers: Set<String> = []
    @Published var speakerOn = true
    @Published var screenSound = true

    private var room: Room?
    private let observer = RoomObserver()

    init() {
        observer.onChange = { [weak self] in
            Task { @MainActor in self?.refresh() }
        }
        observer.onDisconnect = { [weak self] message in
            Task { @MainActor in
                guard let self = self, self.inRoom else { return }
                self.resetState()
                if let message = message { self.error = "انقطع الاتصال: \(message)" }
            }
        }
    }

    // MARK: - Options

    private static func roomOptions(quality: Int) -> RoomOptions {
        let width: Int32
        let height: Int32
        let fps: Int
        let bitrate: Int
        switch quality {
        case 0:   // متوازن
            width = 1920; height = 1080; fps = 30; bitrate = 6_000_000
        case 2:   // نص واضح
            width = 3840; height = 2160; fps = 15; bitrate = 12_000_000
        default:  // أقصى جودة
            width = 3840; height = 2160; fps = 30; bitrate = 20_000_000
        }
        let capture = ScreenShareCaptureOptions(
            dimensions: Dimensions(width: width, height: height),
            fps: fps,
            appAudio: true,
            useScreenCaptureKit: false
        )
        let publish = VideoPublishOptions(
            screenShareEncoding: VideoEncoding(maxBitrate: bitrate, maxFps: fps),
            simulcast: false,
            preferredCodec: .h264,
            degradationPreference: .maintainResolution
        )
        return RoomOptions(defaultScreenShareCaptureOptions: capture,
                           defaultVideoPublishOptions: publish)
    }

    // MARK: - Join / leave

    func join(name: String, room code: String, title: String = "") {
        let d = UserDefaults.standard
        let url = (d.string(forKey: "lkURL") ?? "").trimmingCharacters(in: .whitespaces)
        let key = (d.string(forKey: "lkKey") ?? "").trimmingCharacters(in: .whitespaces)
        let secret = (d.string(forKey: "lkSecret") ?? "").trimmingCharacters(in: .whitespaces)
        let quality = d.object(forKey: "quality") as? Int ?? 1

        guard !url.isEmpty, !key.isEmpty, !secret.isEmpty else {
            error = "افتح الإعدادات (⚙️) وحط رابط LiveKit والمفتاح والسر."
            return
        }
        let n = name.trimmingCharacters(in: .whitespaces)
        let r = code.trimmingCharacters(in: .whitespaces)
        guard !n.isEmpty, !r.isEmpty else {
            error = "اكتب اسمك أول."
            return
        }

        let suffix = String((0..<4).map { _ in "abcdefghijkmnpqrstuvwxyz23456789".randomElement()! })
        let identity = "\(n)#\(suffix)"
        guard let token = TokenMaker.make(apiKey: key, secret: secret, identity: identity, name: n, room: r) else {
            error = "تعذّر إنشاء التوكن."
            return
        }

        roomTitle = title.isEmpty ? r : title
        mutedPeers = []
        speakerOn = true
        screenSound = true
        muted = false
        connecting = true
        UIApplication.shared.isIdleTimerDisabled = true

        let room = Room(delegate: observer)
        self.room = room

        Task { @MainActor in
            do {
                try await room.connect(url: url, token: token, roomOptions: CallModel.roomOptions(quality: quality))
                try await room.localParticipant.setMicrophone(enabled: true)
                AudioManager.shared.mixer.micVolume = 1
                AudioManager.shared.mixer.appVolume = 1
                AudioManager.shared.isSpeakerOutputPreferred = true
                self.connecting = false
                self.inRoom = true
                self.refresh()
            } catch {
                self.resetState()
                self.error = "تعذّر الدخول: \(error)"
            }
        }
    }

    func leave() {
        let r = room
        if BroadcastManager.shared.isBroadcasting { BroadcastManager.shared.requestStop() }
        resetState()
        Task { await r?.disconnect() }
    }

    private func resetState() {
        room = nil
        inRoom = false
        connecting = false
        sharing = false
        meSpeaking = false
        peers = []
        UIApplication.shared.isIdleTimerDisabled = false
    }

    // MARK: - State

    func refresh() {
        guard let room = room else { return }
        var list: [Peer] = []
        for p in room.remoteParticipants.values {
            let id = p.identity?.stringValue ?? UUID().uuidString
            let display = p.name ?? String(id.split(separator: "#").first ?? Substring(id))
            let screenPub = p.trackPublications.values.first { $0.source == .screenShareVideo }
            let screen = screenPub?.track as? VideoTrack
            let key = screenPub.map { String(describing: $0.sid) } ?? "none"
            list.append(Peer(id: id, name: display, screen: screen, screenKey: key, speaking: p.isSpeaking))

            if let audio = p.trackPublications.values.first(where: { $0.source == .microphone })?.track as? RemoteAudioTrack {
                let target: Double = mutedPeers.contains(id) ? 0 : 1
                Task.detached { if audio.volume != target { audio.volume = target } }
            }
        }
        peers = list
        sharing = room.localParticipant.isScreenShareEnabled()
        meSpeaking = room.localParticipant.isSpeaking && !muted
    }

    // MARK: - Controls

    func toggleMute() {
        muted.toggle()
        // نكتم المايك فقط، وصوت الايباد يظل ينبث
        AudioManager.shared.mixer.micVolume = muted ? 0 : 1
        refresh()
    }

    func toggleSpeaker() {
        speakerOn.toggle()
        AudioManager.shared.isSpeakerOutputPreferred = speakerOn
    }

    func toggleScreenSound() {
        screenSound.toggle()
        AudioManager.shared.mixer.appVolume = screenSound ? 1 : 0
    }

    func togglePeerMute(_ id: String) {
        if mutedPeers.contains(id) { mutedPeers.remove(id) } else { mutedPeers.insert(id) }
        refresh()
    }

    func startShare() {
        guard let room = room else { return }
        Task { @MainActor in
            do {
                // يفتح نافذة النظام، وأول ما تبدأ البث ينشر التطبيق الشاشة تلقائياً
                _ = try await room.localParticipant.setScreenShare(enabled: true)
            } catch {
                self.error = "تعذّر بدء البث: \(error)"
            }
        }
    }

    func stopShare() {
        guard let room = room else { return }
        BroadcastManager.shared.requestStop()
        Task { @MainActor in
            _ = try? await room.localParticipant.setScreenShare(enabled: false)
            self.refresh()
        }
    }
}
