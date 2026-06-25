import Foundation

/// Japanese Grapheme-to-Phoneme. Pure-Swift port of misaki's `JAG2P` (pyopenjtalk path).
///
/// The morphological + accent analysis is delegated to a `JAEngine` (OpenJTalk).
/// This class ports the pure-Swift transformation: katakana moras → IPA via `JATables.m2p`,
/// plus the pitch-accent annotation loop. Output is `phonemes + pitch` concatenated,
/// matching `ja.py` (`return result + pitch, tokens`).
public final class JAG2P {

    private let engine: JAEngine
    private let unk: String

    public init(engine: JAEngine, unk: String = "\u{2753}") {
        self.engine = engine
        self.unk = unk
    }

    /// Split a katakana pronunciation into moras (mirrors `JAG2P.pron2moras`).
    /// Greedily merges a following kana into the previous mora when the pair is a valid
    /// M2P key (e.g. キ + ャ → キャ). Chars absent from M2P are skipped.
    public static func pron2moras(_ pron: String) -> [String] {
        var moras: [String] = []
        for ch in pron {
            let k = String(ch)
            if JATables.m2p[k] == nil { continue }
            if let last = moras.last, JATables.m2p[last + k] != nil {
                moras[moras.count - 1] = last + k
            } else {
                moras.append(k)
            }
        }
        return moras
    }

    /// Convert text to a (phonemes+pitch, tokens) pair.
    public func phonemize(_ text: String) -> (String, [JAToken]) {
        var tokens: [JAToken] = []
        var lastA = 0
        var acc: Int? = nil
        var mcount = 0

        for word in engine.runFrontend(text) {
            let pron = word.pron
            let moraSize = word.moraSize
            var moras: [String] = []
            if moraSize > 0 {
                moras = Self.pron2moras(pron)
            }

            let chainFlag = moraSize > 0 && !tokens.isEmpty && tokens.last!.moraSize > 0
                && (word.chainFlag == 1 || moras.first == "\u{30FC}")  // ー

            if !chainFlag { acc = nil; mcount = 0 }
            if acc == nil { acc = word.acc }
            let accVal = acc ?? 0

            var accents: [Int] = []
            for _ in moras {
                mcount += 1
                let a: Int
                if accVal == 0 {
                    a = mcount == 1 ? 0 : (lastA == 0 ? 1 : 2)
                } else if accVal == mcount {
                    a = 3
                } else if mcount > 1 && mcount < accVal {
                    a = lastA == 0 ? 1 : 2
                } else {
                    a = 0
                }
                accents.append(a)
                lastA = a
            }

            // Surface, with full-width punctuation mapped.
            var surface = word.string
            if surface.count == 1, let only = surface.first, let mapped = JATables.punctMap[only] {
                surface = String(mapped)
            }

            var whitespace = ""
            var phonemes: String? = nil
            var pitch: String? = nil

            if !moras.isEmpty {
                var ph = ""
                var pi = ""
                for (m, a) in zip(moras, accents) {
                    guard let ps = JATables.m2p[m] else { continue }
                    ph += ps
                    let mark: Character = a == 0 ? "_" : (a == 3 ? "^" : "-")
                    pi += String(repeating: mark, count: ps.count)
                }
                phonemes = ph
                pitch = pi
            } else if !surface.isEmpty && surface.allSatisfy({ JATables.punctValues.contains($0) }) {
                phonemes = surface
                if let last = surface.last, JATables.punctStops.contains(last) {
                    whitespace = " "
                    if let prev = tokens.last { prev.whitespace = "" }
                } else if let last = surface.last, JATables.punctStarts.contains(last),
                          let prev = tokens.last, prev.whitespace.isEmpty {
                    prev.whitespace = " "
                }
            }

            // Skip middle-dot / whitespace-only surfaces: bump previous token's whitespace.
            let isInterpunct = !tokens.isEmpty && phonemes == nil && surface == "\u{30FB}"  // ・
            let isBlank = !surface.isEmpty && surface.trimmingCharacters(in: .whitespaces).isEmpty
            if isInterpunct || isBlank {
                tokens.last?.whitespace = " "
                continue
            }

            tokens.append(JAToken(
                text: surface, tag: word.pos, whitespace: whitespace, phonemes: phonemes,
                pron: pron, acc: word.acc, moraSize: moraSize, chainFlag: chainFlag,
                moras: moras, accents: accents, pitch: pitch
            ))
        }

        // Assemble result + pitch.
        var result = ""
        var pitchStr = ""
        for tk in tokens {
            guard let ph = tk.phonemes else {
                let chunk = unk + tk.whitespace
                result += chunk
                pitchStr += String(repeating: "j", count: chunk.count)
                continue
            }
            if tk.moraSize > 0 && !tk.chainFlag && !result.isEmpty,
               let last = result.last, JATables.tails.contains(last), tk.moras.first != "\u{30F3}" /* ン */ {
                result += " "
                pitchStr += "j"
            }
            result += ph + tk.whitespace
            let phPitch = tk.pitch ?? String(repeating: "j", count: ph.count)
            pitchStr += phPitch + String(repeating: "j", count: tk.whitespace.count)
        }

        // Trim trailing whitespace contributed by the last token.
        if let last = tokens.last, !last.whitespace.isEmpty, result.hasSuffix(last.whitespace) {
            result = String(result.dropLast(last.whitespace.count))
            pitchStr = String(pitchStr.prefix(result.count))
        }

        return (result + pitchStr, tokens)
    }
}
