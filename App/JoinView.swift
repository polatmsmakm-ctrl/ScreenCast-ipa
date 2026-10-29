import SwiftUI

struct JoinView: View {
    @ObservedObject var model: CallModel
    @Binding var showSettings: Bool
    @AppStorage("userName") private var name = ""
    @AppStorage("lastRoom") private var room = ""

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(red: 0.06, green: 0.07, blue: 0.14),
                                    Color(red: 0.10, green: 0.05, blue: 0.20)],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()

            VStack(spacing: 22) {
                HStack {
                    Spacer()
                    Button { showSettings = true } label: {
                        Image(systemName: "gearshape.fill")
                            .font(.title2)
                            .foregroundColor(.white.opacity(0.8))
                            .padding(10)
                    }
                }

                Spacer()

                Image(systemName: "rectangle.on.rectangle.angled")
                    .font(.system(size: 64, weight: .semibold))
                    .foregroundColor(.white)
                Text("بث")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundColor(.white)
                Text("شارك شاشتك مع أصدقائك وسولفوا بصوت")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))

                VStack(spacing: 12) {
                    field("اسمك", text: $name, icon: "person.fill")
                    field("اسم الغرفة", text: $room, icon: "number")
                }
                .frame(maxWidth: 420)
                .padding(.top, 10)

                Button {
                    model.join(name: name, room: room)
                } label: {
                    HStack {
                        if model.connecting { ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white)) }
                        Text(model.connecting ? "جاري الدخول..." : "ادخل الغرفة")
                            .font(.headline)
                    }
                    .frame(maxWidth: 420)
                    .padding(.vertical, 16)
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(16)
                }
                .disabled(model.connecting)

                Spacer()
                Spacer()
            }
            .padding(.horizontal, 24)
        }
    }

    private func field(_ title: String, text: Binding<String>, icon: String) -> some View {
        HStack {
            Image(systemName: icon).foregroundColor(.white.opacity(0.6))
            TextField(title, text: text)
                .autocapitalization(.none)
                .disableAutocorrection(true)
                .foregroundColor(.white)
        }
        .padding(14)
        .background(Color.white.opacity(0.1))
        .cornerRadius(14)
    }
}
