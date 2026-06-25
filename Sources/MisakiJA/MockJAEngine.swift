import Foundation

/// A trivial `JAEngine` that replays a pre-baked word list — for testing the
/// pure-Swift accent/IPA layer without the (not-yet-built) OpenJTalk C bridge.
/// Captured NJD features from pyopenjtalk can be hard-coded here as fixtures.
public struct MockJAEngine: JAEngine {
    private let words: [NJDWord]
    public init(_ words: [NJDWord]) { self.words = words }
    public func runFrontend(_ text: String) -> [NJDWord] { words }
}
