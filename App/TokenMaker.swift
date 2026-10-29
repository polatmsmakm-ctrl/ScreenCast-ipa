import Foundation
import CryptoKit

/// يصنع توكن الدخول (JWT) محلياً من مفتاح LiveKit السري. مناسب لتطبيق خاص بالأصدقاء.
enum TokenMaker {
    private static func b64url(_ data: Data) -> String {
        data.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }

    static func make(apiKey: String, secret: String, identity: String, name: String,
                     room: String, ttl: TimeInterval = 6 * 3600) -> String? {
        let now = Int(Date().timeIntervalSince1970)
        let header: [String: Any] = ["alg": "HS256", "typ": "JWT"]
        let payload: [String: Any] = [
            "iss": apiKey,
            "sub": identity,
            "name": name,
            "nbf": now - 10,
            "exp": now + Int(ttl),
            "video": [
                "room": room,
                "roomJoin": true,
                "canPublish": true,
                "canSubscribe": true,
                "canPublishData": true,
            ] as [String: Any],
        ]
        guard let h = try? JSONSerialization.data(withJSONObject: header),
              let p = try? JSONSerialization.data(withJSONObject: payload) else { return nil }
        let input = b64url(h) + "." + b64url(p)
        let key = SymmetricKey(data: Data(secret.utf8))
        let sig = HMAC<SHA256>.authenticationCode(for: Data(input.utf8), using: key)
        return input + "." + b64url(Data(sig))
    }
}
