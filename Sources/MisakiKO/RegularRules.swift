import Foundation

/// Port of g2pkc/regular.py — liaison (linking) rules. Plain string replacement.
/// link3 intentionally omitted (g2pk pipeline skips it).
enum RegularRules {

    // 13
    static func link1(_ inp: String, _ descriptive: Bool = false) -> String {
        let pairs: [(String, String)] = [
            ("\u{11A8}\u{110B}", "\u{1100}"), ("\u{11A9}\u{110B}", "\u{1101}"),
            ("\u{11AB}\u{110B}", "\u{1102}"), ("\u{11AE}\u{110B}", "\u{1103}"),
            ("\u{11AF}\u{110B}", "\u{1105}"), ("\u{11B7}\u{110B}", "\u{1106}"),
            ("\u{11B8}\u{110B}", "\u{1107}"), ("\u{11BA}\u{110B}", "\u{1109}"),
            ("\u{11BB}\u{110B}", "\u{110A}"), ("\u{11BD}\u{110B}", "\u{110C}"),
            ("\u{11BE}\u{110B}", "\u{110E}"), ("\u{11BF}\u{110B}", "\u{110F}"),
            ("\u{11C0}\u{110B}", "\u{1110}"), ("\u{11C1}\u{110B}", "\u{1111}"),
        ]
        return replaceAll(inp, pairs)
    }

    // 14
    static func link2(_ inp: String, _ descriptive: Bool = false) -> String {
        let pairs: [(String, String)] = [
            ("\u{11AA}\u{110B}", "\u{11A8}\u{110A}"), ("\u{11AC}\u{110B}", "\u{11AB}\u{110C}"),
            ("\u{11B0}\u{110B}", "\u{11AF}\u{1100}"), ("\u{11B1}\u{110B}", "\u{11AF}\u{1106}"),
            ("\u{11B2}\u{110B}", "\u{11AF}\u{1107}"), ("\u{11B3}\u{110B}", "\u{11AF}\u{110A}"),
            ("\u{11B4}\u{110B}", "\u{11AF}\u{1110}"), ("\u{11B5}\u{110B}", "\u{11AF}\u{1111}"),
            ("\u{11B9}\u{110B}", "\u{11B8}\u{110A}"),
        ]
        return replaceAll(inp, pairs)
    }

    // 12.4
    static func link4(_ inp: String, _ descriptive: Bool = false) -> String {
        let pairs: [(String, String)] = [
            ("\u{11C2}\u{110B}", "\u{110B}"),  // ᇂᄋ → ᄋ
            ("\u{11AD}\u{110B}", "\u{1102}"),  // ᆭᄋ → ᄂ
            ("\u{11B6}\u{110B}", "\u{1105}"),  // ᆶᄋ → ᄅ
        ]
        return replaceAll(inp, pairs)
    }

    /// Apply link1, link2, link4 in order (link3 omitted, as in g2pk.py).
    static func applyLinks(_ inp: String, _ descriptive: Bool) -> String {
        link4(link2(link1(inp, descriptive), descriptive), descriptive)
    }

    private static func replaceAll(_ s: String, _ pairs: [(String, String)]) -> String {
        var out = s
        // `.literal` is essential: default replacement uses canonical equivalence, which
        // fails to find conjoining-jamo sequences that straddle grapheme-cluster boundaries.
        for (a, b) in pairs { out = out.replacingOccurrences(of: a, with: b, options: .literal) }
        return out
    }
}
