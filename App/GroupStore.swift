import SwiftUI
import UIKit

struct ChatGroup: Identifiable, Codable, Equatable {
    var id = UUID()
    var name: String
    var code: String
}

final class GroupStore: ObservableObject {
    @Published var items: [ChatGroup] = [] {
        didSet { save() }
    }

    private let key = "savedGroups"

    init() {
        if let data = UserDefaults.standard.data(forKey: key),
           let list = try? JSONDecoder().decode([ChatGroup].self, from: data) {
            items = list
        }
    }

    private func save() {
        if let data = try? JSONEncoder().encode(items) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    static func randomCode() -> String {
        let chars = Array("ABCDEFGHJKLMNPQRSTUVWXYZ23456789")
        return String((0..<6).map { _ in chars.randomElement()! })
    }

    @discardableResult
    func create(name: String) -> Group {
        let g = ChatGroup(name: name, code: GroupStore.randomCode())
        items.insert(g, at: 0)
        return g
    }

    @discardableResult
    func join(code: String, name: String) -> Group {
        let c = code.trimmingCharacters(in: .whitespaces).uppercased()
        if let existing = items.first(where: { $0.code == c }) { return existing }
        let n = name.trimmingCharacters(in: .whitespaces)
        let g = ChatGroup(name: n.isEmpty ? "مجموعة \(c)" : n, code: c)
        items.insert(g, at: 0)
        return g
    }

    func delete(at offsets: IndexSet) {
        items.remove(atOffsets: offsets)
    }

    func remove(_ g: ChatGroup) {
        items.removeAll { $0.id == g.id }
    }
}

struct ShareItem: Identifiable {
    let id = UUID()
    let text: String

    init(group: ChatGroup) {
        text = "ادخل مجموعة «\(group.name)» في تطبيق بث 📺\nافتح التطبيق ← + ← انضمام، واكتب الكود: \(group.code)"
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let text: String

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [text], applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
