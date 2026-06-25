import Foundation

/// One analyzed word from a Japanese frontend (mirrors a pyopenjtalk `run_frontend`
/// NJD feature dict — the fields ja.py actually reads).
public struct NJDWord: Sendable {
    public let string: String     // surface form (word['string'])
    public let pron: String       // katakana pronunciation (word['pron'])
    public let pos: String        // part of speech (word['pos'])
    public let acc: Int           // accent nucleus position (word['acc'])
    public let moraSize: Int      // mora count (word['mora_size'])
    public let chainFlag: Int     // accent-phrase chaining (-1/0/1) (word['chain_flag'])

    public init(string: String, pron: String, pos: String, acc: Int, moraSize: Int, chainFlag: Int) {
        self.string = string
        self.pron = pron
        self.pos = pos
        self.acc = acc
        self.moraSize = moraSize
        self.chainFlag = chainFlag
    }
}

/// A Japanese morphological + accent frontend. The pure-Swift `JAG2P` consumes this.
/// Concrete impl (OpenJTalk via C bridge) is a separate target — TODO.
public protocol JAEngine {
    func runFrontend(_ text: String) -> [NJDWord]
}

/// Japanese token with phonemes + pitch annotation (mirrors misaki MToken + Underscore).
/// Reference type because the loop mutates the previous token's `whitespace`.
public final class JAToken {
    public var text: String
    public var tag: String
    public var whitespace: String
    public var phonemes: String?   // nil = non-phonemic / unknown

    // Underscore fields
    public var pron: String
    public var acc: Int
    public var moraSize: Int
    public var chainFlag: Bool
    public var moras: [String]
    public var accents: [Int]
    public var pitch: String?

    init(text: String, tag: String, whitespace: String, phonemes: String?,
         pron: String, acc: Int, moraSize: Int, chainFlag: Bool,
         moras: [String], accents: [Int], pitch: String?) {
        self.text = text
        self.tag = tag
        self.whitespace = whitespace
        self.phonemes = phonemes
        self.pron = pron
        self.acc = acc
        self.moraSize = moraSize
        self.chainFlag = chainFlag
        self.moras = moras
        self.accents = accents
        self.pitch = pitch
    }
}
