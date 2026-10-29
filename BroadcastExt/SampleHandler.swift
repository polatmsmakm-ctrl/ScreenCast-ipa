import LiveKit

// يرسل شاشة الايباد وصوته للتطبيق الرئيسي عن طريق App Group
class SampleHandler: LKSampleHandler {
    override var enableLogging: Bool { true }
}
