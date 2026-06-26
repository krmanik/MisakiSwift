import Foundation
import CppOpenJTalk

/// Swift wrapper over CppMecab loaded with mecab-ko-dic. Provides `pos`
/// (surface, POS) tagging equivalent to python-mecab-ko's `MeCab().pos()`.
public final class MecabKo: @unchecked Sendable {
    private let handle: MecabHandle

    /// Load mecab-ko-dic from this module's bundled resources. Returns nil if absent.
    public static let shared: MecabKo? = {
        guard let url = Bundle.module.url(forResource: "mecab-ko-dic", withExtension: nil) else {
            return nil
        }
        return MecabKo(dicDir: url.path)
    }()

    public init?(dicDir: String) {
        guard let h = mecab_bridge_create(dicDir) else { return nil }
        self.handle = h
    }

    deinit { mecab_bridge_destroy(handle) }

    /// Tag `text` → array of (surface, POS). POS is the mecab-ko-dic feature field 0
    /// (may be a "+"-joined compound for inflected forms).
    public func pos(_ text: String) -> [(surface: String, pos: String)] {
        let result = text.withCString { mecab_bridge_analyze(handle, $0) }
        defer { mecab_bridge_free_result(result) }
        guard let feats = result.features else { return [] }
        var out: [(String, String)] = []
        out.reserveCapacity(result.count)
        for i in 0..<result.count {
            guard let cstr = feats[i] else { continue }
            let feature = String(cString: cstr)
            // Format: "surface,POS,semantic,...". Surface is before the first comma.
            let parts = feature.components(separatedBy: ",")
            let surface = parts.first ?? ""
            let posTag = parts.count > 1 ? parts[1] : "*"
            out.append((surface, posTag))
        }
        return out
    }
}
