import Foundation

/// Korean Grapheme-to-Phoneme. Pure-Swift port of misaki's g2pkc (kyubyong/g2pK).
///
/// Mirrors `g2pk.py.G2p.__call__`. The 9-step pipeline:
///   1 idioms → 2 English→Hangul → 3 annotate (mecab, TODO) → 4 numerals →
///   5 decompose (h2j) → 6 special → 7 table → 8 link → 9 compose/cleanup
///
/// v0 limitations (pure Swift, zero native deps):
///   - step 3 `annotate` requires mecab-ko; disabled by default (`useDict=false`).
///     Without it, particle-boundary tensification (/P /J /E /B rules) does not fire.
///   - step 2 English path uses letter-spelling only (see KOEnglish).
public final class KOG2P {

    private let idioms: [(String, String)]
    private let table: [(String, String, [String])]

    public init() {
        self.idioms = KOG2P.loadIdioms()
        self.table = KOUtils.parseTable()
    }

    /// Convert text to a jamo/phoneme string (matches Python `KOG2P.__call__` return).
    public func phonemize(
        _ text: String,
        descriptive: Bool = false,
        groupVowels: Bool = false,
        toSyllable: Bool = false,
        useDict: Bool = false   // v0 default: no mecab
    ) -> String {
        var string = text

        // 1. idioms
        string = applyIdioms(string)

        // 2. English → Hangul
        string = KOEnglish.convertEng(string)

        // 3. annotate (mecab POS tags)  — TODO: requires CppMecab + mecab-ko-dic
        if useDict {
            // string = annotate(string)
        }

        // 4. numerals
        string = KONumerals.convertNum(string)

        // 5. decompose to conjoining jamo
        var inp = Jamo.h2j(string)

        // 6. special rules
        inp = SpecialRules.applyAll(inp, descriptive)
        inp = RE.sub("/[PJEB]", "", inp)

        // 7. regular table: batchim + onset
        for (str1, str2, _) in table {
            inp = RE.sub(str1, str2, inp)
        }

        // 8. link
        inp = RegularRules.applyLinks(inp, descriptive)

        // 9. postprocessing
        if groupVowels { inp = KOUtils.group(inp) }
        if toSyllable { inp = KOUtils.compose(inp) }
        inp = inp.replacingOccurrences(of: "^", with: "")
        return inp
    }

    // MARK: - idioms

    private func applyIdioms(_ string: String) -> String {
        var out = string
        for (str1, str2) in idioms {
            out = RE.sub(str1, str2, out)
        }
        return out
    }

    private static func loadIdioms() -> [(String, String)] {
        guard let url = Bundle.module.url(forResource: "idioms", withExtension: "txt"),
              let raw = try? String(contentsOf: url, encoding: .utf8) else {
            return []
        }
        var pairs: [(String, String)] = []
        for line in raw.components(separatedBy: .newlines) {
            // Strip trailing comment.
            let noComment = line.components(separatedBy: "#").first ?? ""
            guard noComment.contains("===") else { continue }
            let parts = noComment.components(separatedBy: "===")
            guard parts.count == 2 else { continue }
            pairs.append((parts[0], parts[1]))
        }
        return pairs
    }
}
