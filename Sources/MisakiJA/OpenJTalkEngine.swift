import Foundation
import CppOpenJTalk

/// `JAEngine` backed by the vendored OpenJTalk frontend (mecab + NJD) via CppOpenJTalk.
/// Runs the same text2mecab → mecab → mecab2njd → njd_set_* pipeline as pyopenjtalk's
/// `run_frontend`, returning per-word NJD features.
public final class OpenJTalkEngine: JAEngine, @unchecked Sendable {
    private let handle: OJTHandle

    public enum InitError: Error, LocalizedError {
        case dictionaryNotFound
        case engineInitFailed
        public var errorDescription: String? {
            switch self {
            case .dictionaryNotFound: return "OpenJTalk dictionary (open_jtalk_dic) not found in bundle"
            case .engineInitFailed: return "OpenJTalk engine failed to load the dictionary"
            }
        }
    }

    /// Load using the dictionary bundled in this module's resources.
    public convenience init() throws {
        guard let dicURL = Bundle.module.url(forResource: "open_jtalk_dic", withExtension: nil) else {
            throw InitError.dictionaryNotFound
        }
        try self.init(dictDir: dicURL.path)
    }

    /// Load from an explicit dictionary directory path.
    public init(dictDir: String) throws {
        guard let h = ojt_create(dictDir) else { throw InitError.engineInitFailed }
        self.handle = h
    }

    deinit { ojt_destroy(handle) }

    public func runFrontend(_ text: String) -> [NJDWord] {
        let result = text.withCString { ojt_run_frontend(handle, $0) }
        defer { ojt_free_result(result) }
        guard let words = result.words else { return [] }
        var out: [NJDWord] = []
        out.reserveCapacity(result.count)
        for i in 0..<result.count {
            let w = words[i]
            out.append(NJDWord(
                string: w.string.map { String(cString: $0) } ?? "",
                pron: w.pron.map { String(cString: $0) } ?? "",
                pos: w.pos.map { String(cString: $0) } ?? "",
                acc: Int(w.acc),
                moraSize: Int(w.mora_size),
                chainFlag: Int(w.chain_flag)
            ))
        }
        return out
    }
}

public extension JAG2P {
    /// Convenience: a `JAG2P` driven by the bundled OpenJTalk engine.
    static func openJTalk(unk: String = "\u{2753}") throws -> JAG2P {
        JAG2P(engine: try OpenJTalkEngine(), unk: unk)
    }
}
