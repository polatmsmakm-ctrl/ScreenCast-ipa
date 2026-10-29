import SwiftUI

struct CallView: View {
    @ObservedObject var model: CallModel
    @State private var focused: String?
    private let pickerBox = PickerBox()

    private var screens: [CallModel.Peer] {
        model.peers.filter { $0.kind != .none }
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

            // نافذة اختيار البث حق النظام (مخفية، نضغطها برمجياً)
            BroadcastPicker(box: pickerBox)
                .frame(width: 44, height: 44)
                .opacity(0.011)
                .allowsHitTesting(false)
        }
    }

    // MARK: - Top bar

    private var topBar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(model.room)
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
            RemoteVideoView(userId: p.id, isSub: p.kind == .sub)
                .id("\(p.id)-\(p.kind == .sub)")
            Text(p.id)
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
            HStack(spacing: 12) {
                avatar("أنت", highlight: model.sharing)
                ForEach(model.peers) { p in
                    avatar(p.id, highlight: p.kind != .none)
                }
            }
            .padding(.horizontal, 16)
        }
        .frame(height: 64)
    }

    private func avatar(_ name: String, highlight: Bool) -> some View {
        VStack(spacing: 4) {
            Text(String(name.prefix(1)).uppercased())
                .font(.headline)
                .frame(width: 38, height: 38)
                .background(highlight ? Color.red : Color.white.opacity(0.15))
                .foregroundColor(.white)
                .clipShape(Circle())
            Text(name)
                .font(.system(size: 10))
                .foregroundColor(.white.opacity(0.7))
                .lineLimit(1)
                .frame(maxWidth: 60)
        }
    }

    // MARK: - Controls

    private var controls: some View {
        HStack(spacing: 18) {
            roundButton(model.muted ? "mic.slash.fill" : "mic.fill",
                        color: model.muted ? .red : Color.white.opacity(0.18)) {
                model.toggleMute()
            }

            Button {
                if model.sharing { model.stopShare() } else { model.startShare(picker: pickerBox) }
            } label: {
                HStack {
                    Image(systemName: model.sharing ? "stop.fill" : "rectangle.on.rectangle")
                    Text(model.sharing ? "أوقف البث" : "ابدأ بث الشاشة")
                        .font(.headline)
                }
                .padding(.horizontal, 22).padding(.vertical, 14)
                .background(model.sharing ? Color.red : Color.accentColor)
                .foregroundColor(.white)
                .clipShape(Capsule())
            }

            Menu {
                Button("720p سلس (30 إطار)") { model.quality = 0 }
                Button("1080p عالي (30 إطار)") { model.quality = 1 }
                Button("1080p نص واضح (15 إطار)") { model.quality = 2 }
            } label: {
                Image(systemName: "slider.horizontal.3")
                    .font(.title3)
                    .frame(width: 50, height: 50)
                    .background(Color.white.opacity(0.18))
                    .foregroundColor(.white)
                    .clipShape(Circle())
            }

            roundButton("phone.down.fill", color: .red) {
                model.leave()
            }
        }
        .padding(.vertical, 14)
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
