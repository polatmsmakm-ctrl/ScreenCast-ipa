import SwiftUI

struct HomeView: View {
    @ObservedObject var model: CallModel
    @ObservedObject var groups: GroupStore
    @Binding var showSettings: Bool
    @AppStorage("userName") private var name = ""

    @State private var showAdd = false
    @State private var shareItem: ShareItem?

    var body: some View {
        NavigationView {
            List {
                Section(header: Text("اسمك")) {
                    HStack {
                        Image(systemName: "person.fill").foregroundColor(.secondary)
                        TextField("اكتب اسمك", text: $name)
                            .disableAutocorrection(true)
                    }
                }

                Section(header: Text("مجموعاتك")) {
                    if groups.items.isEmpty {
                        VStack(spacing: 10) {
                            Image(systemName: "person.3.fill")
                                .font(.system(size: 38))
                                .foregroundColor(.secondary)
                            Text("ما عندك مجموعات بعد")
                                .foregroundColor(.secondary)
                            Button("+ أضف مجموعة") { showAdd = true }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 24)
                    }
                    ForEach(groups.items) { g in
                        row(g)
                    }
                    .onDelete(perform: groups.delete)
                }
            }
            .navigationBarTitle("بث")
            .navigationBarItems(
                leading: Button { showSettings = true } label: {
                    Image(systemName: "gearshape.fill")
                },
                trailing: Button { showAdd = true } label: {
                    Image(systemName: "plus.circle.fill").font(.title3)
                }
            )
            .overlay(
                Group {
                    if model.connecting {
                        ZStack {
                            Color.black.opacity(0.5).ignoresSafeArea()
                            ProgressView("جاري الدخول...")
                                .padding(20)
                                .background(Color(UIColor.secondarySystemBackground))
                                .cornerRadius(14)
                        }
                    }
                }
            )
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .sheet(isPresented: $showAdd) {
            AddGroupView(groups: groups) { created in
                shareItem = ShareItem(group: created)
            }
            .environment(\.layoutDirection, .rightToLeft)
            .preferredColorScheme(.dark)
        }
        .sheet(item: $shareItem) { item in
            ShareSheet(text: item.text)
        }
    }

    private func row(_ g: ChatGroup) -> some View {
        HStack(spacing: 12) {
            Text(String(g.name.prefix(1)))
                .font(.headline)
                .frame(width: 44, height: 44)
                .background(Color.accentColor.opacity(0.85))
                .foregroundColor(.white)
                .clipShape(Circle())
            VStack(alignment: .leading, spacing: 3) {
                Text(g.name).font(.headline)
                Text("الكود: \(g.code)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Button { shareItem = ShareItem(group: g) } label: {
                Image(systemName: "person.badge.plus")
                    .font(.title3)
            }
            .buttonStyle(BorderlessButtonStyle())
            Button {
                model.join(name: name, room: g.code, title: g.name)
            } label: {
                Text("ادخل")
                    .font(.subheadline.bold())
                    .padding(.horizontal, 16).padding(.vertical, 8)
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .clipShape(Capsule())
            }
            .buttonStyle(BorderlessButtonStyle())
        }
        .padding(.vertical, 4)
        .contextMenu {
            Button { shareItem = ShareItem(group: g) } label: {
                Label("ادعُ أصدقاءك", systemImage: "person.badge.plus")
            }
            Button { groups.remove(g) } label: {
                Label("احذف المجموعة", systemImage: "trash")
            }
        }
    }
}

struct AddGroupView: View {
    @Environment(\.presentationMode) private var presentation
    @ObservedObject var groups: GroupStore
    var onCreated: (ChatGroup) -> Void

    @State private var mode = 0
    @State private var name = ""
    @State private var code = ""

    var body: some View {
        NavigationView {
            Form {
                Picker("", selection: $mode) {
                    Text("مجموعة جديدة").tag(0)
                    Text("انضمام بكود").tag(1)
                }
                .pickerStyle(SegmentedPickerStyle())

                if mode == 0 {
                    Section(footer: Text("بعد الإنشاء تطلع لك قائمة المشاركة عشان ترسل الكود لأصدقائك.")) {
                        TextField("اسم المجموعة (مثلاً: الشلّة)", text: $name)
                    }
                    Section {
                        Button("إنشاء المجموعة") {
                            let n = name.trimmingCharacters(in: .whitespaces)
                            guard !n.isEmpty else { return }
                            let g = groups.create(name: n)
                            presentation.wrappedValue.dismiss()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { onCreated(g) }
                        }
                    }
                } else {
                    Section(footer: Text("اطلب الكود من صديقك اللي أنشأ المجموعة.")) {
                        TextField("الكود", text: $code)
                            .autocapitalization(.allCharacters)
                            .disableAutocorrection(true)
                        TextField("اسم تعرفه فيه (اختياري)", text: $name)
                    }
                    Section {
                        Button("انضم") {
                            guard !code.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                            groups.join(code: code, name: name)
                            presentation.wrappedValue.dismiss()
                        }
                    }
                }
            }
            .navigationBarTitle("إضافة مجموعة", displayMode: .inline)
            .navigationBarItems(trailing: Button("إلغاء") { presentation.wrappedValue.dismiss() })
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}
