import SwiftUI
import LiveKit

struct CallView: View {
    @ObservedObject var model: CallModel
    @State private var focused: String?

    private var screens: [CallModel.Peer] {
        model.peers.filter { $0.screen != nil }
    }

    var body: some View {
        ZStack {
            Color(red: 0.05, green: 0.05, blue: 0.09).ignoresSafeArea()

            VStack(spacing: 0) {
                topBar
                stage
                peersBar
                controls
            }
        }
    }

    // MARK: - Top bar

    private var topBar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(model.roomTitle)
                    .font(.headline)
                    .foregroundColor(.white)
                Text("\(model.peers.count + 1) في الغرفة")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
            }
            Spacer()
            if model.sharing {
                Label("أنت تبث", systemImage: "dot.radiowaves.left.and.right")
                    .font(.caption.bold())
                    .padding(.horizontal, 10).padding(.vertical, 6)
                    .background(Color.red)
                    .foregroundColor(.white)
                    .clipShape(Capsule())
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    // MARK: - Stage

    @ViewBuilder
    private var stage: some View {
        if screens.isEmpty {
            VStack(spacing: 12) {
                Spacer()
                Image(systemName: "tv")
                    .font(.system(size: 54))
                    .foregroundColor(.white.opacity(0.3))
                Text("ما أحد يبث الحين")
                    .foregroundColor(.white.opacity(0.5))
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if let f = focused, let p = screens.first(where: { $0.id == f }) {
            tile(p)
                .onTapGesture { focused = nil }
                .padding(8)
        } else {
            GeometryReader { geo in
                let wide = geo.size.width > geo.size.height
                let cols = screens.count == 1 ? 1 : (wide ? 2 : 1)
                ScrollView {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: cols),
                              spacing: 8) {
                        ForEach(screens) { p in
                            tile(p)
                                .aspectRatio(16.0 / 9.0, contentMode: .fit)
                                .onTapGesture { focused = p.id }
                        }
                    }
                    .padding(8)
                }
            }
        }
    }

    private func tile(_ p: CallModel.Peer) -> some View {
        ZStack(alignment: .bottomLeading) {
            if let t = p.screen {
                SwiftUIVideoView(t, layoutMode: .fit)
                    .id(p.screenKey)
            }
            Text(p.name)
                .font(.caption.bold())
                .padding(.horizontal, 10).padding(.vertical, 5)
                .background(Color.black.opacity(0.55))
                .foregroundColor(.white)
                .clipShape(Capsule())
                .padding(8)
        }
        .cornerRadius(14)
    }

    // MARK: - Peers

    private var peersBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 14) {
                avatar("أنت", id: nil, highlight: model.sharing,
                       speaking: model.meSpeaking,
                       muted: model.muted)
                ForEach(model.peers) { p in
                    avatar(p.name, id: p.id, highlight: p.screen != nil,
                           speaking: p.speaking && !model.mutedPeers.contains(p.id),
                           muted: model.mutedPeers.contains(p.id))
                }
            }
            .padding(.horizontal, 16)
        }
        .frame(height: 72)
    }

    private func avatar(_ name: String, id: String?, highlight: Bool, speaking: Bool, muted: Bool) -> some View {
        Button {
            if let id = id { model.togglePeerMute(id) }
        } label: {
            VStack(spacing: 4) {
                ZStack(alignment: .bottomTrailing) {
                    Text(String(name.prefix(1)).uppercased())
                        .font(.headline)
                        .frame(width: 40, height: 40)
                        .background(highlight ? Color.red : Color.white.opacity(0.15))
                        .foregroundColor(.white)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.green, lineWidth: speaking ? 3 : 0))
                    if muted {
                        Image(systemName: "mic.slash.fill")
                            .font(.system(size: 9))
                            .padding(4)
                            .background(Color.red)
                            .foregroundColor(.white)
                            .clipShape(Circle())
                            .offset(x: 4, y: 2)
                    }
                }
                Text(name)
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.7))
                    .lineLimit(1)
                    .frame(maxWidth: 60)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - Controls

    private var controls: some View {
        VStack(spacing: 12) {
            if model.sharing {
                HStack(spacing: 8) {
                    Image(systemName: model.screenSound ? "speaker.wave.2.fill" : "speaker.slash.fill")
                    Text(model.screenSound ? "صوت الايباد ينبث" : "صوت الايباد مكتوم")
                        .font(.caption)
                    Spacer()
                    Button(model.screenSound ? "اكتمه" : "شغّله") { model.toggleScreenSound() }
                        .font(.caption.bold())
                }
                .foregroundColor(.white)
                .padding(.horizontal, 14).padding(.vertical, 8)
                .background(Color.white.opacity(0.12))
                .cornerRadius(12)
                .padding(.horizontal, 16)
            }

            HStack(spacing: 14) {
                roundButton(model.muted ? "mic.slash.fill" : "mic.fill",
                            color: model.muted ? .red : Color.white.opacity(0.18)) {
                    model.toggleMute()
                }

                roundButton(model.speakerOn ? "speaker.wave.3.fill" : "phone.fill",
                            color: Color.white.opacity(0.18)) {
                    model.toggleSpeaker()
                }

                Button {
                    if model.sharing { model.stopShare() } else { model.startShare() }
                } label: {
                    HStack {
                        Image(systemName: model.sharing ? "stop.fill" : "rectangle.on.rectangle")
                        Text(model.sharing ? "أوقف البث" : "بث الشاشة")
                            .font(.headline)
                    }
                    .padding(.horizontal, 20).padding(.vertical, 14)
                    .background(model.sharing ? Color.red : Color.accentColor)
                    .foregroundColor(.white)
                    .clipShape(Capsule())
                }

                roundButton("phone.down.fill", color: .red) {
                    model.leave()
                }
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 12)
    }

    private func roundButton(_ icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.title3)
                .frame(width: 50, height: 50)
                .background(color)
                .foregroundColor(.white)
                .clipShape(Circle())
        }
    }
}
