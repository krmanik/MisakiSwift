import Foundation

/// Port of g2pkc/special.py — special Hangul pronunciation rules.
/// Operate on conjoining-jamo strings. `descriptive` defaults to false (misaki default).
enum SpecialRules {

    /// Apply all 12 special rules in order (mirrors the special-func loop in g2pk.py).
    static func applyAll(_ inp: String, _ descriptive: Bool) -> String {
        var s = inp
        s = jyeo(s, descriptive)
        s = ye(s, descriptive)
        s = consonantUi(s, descriptive)
        s = josaUi(s, descriptive)
        s = vowelUi(s, descriptive)
        s = jamo(s, descriptive)
        s = rieulgiyeok(s, descriptive)
        s = rieulbieub(s, descriptive)
        s = verbNieun(s, descriptive)
        s = balb(s, descriptive)
        s = palatalize(s, descriptive)
        s = modifyingRieul(s, descriptive)
        return s
    }

    // 5.1
    static func jyeo(_ inp: String, _ descriptive: Bool = false) -> String {
        RE.sub("([\u{110C}\u{110D}\u{110E}])\u{1167}", "$1\u{1165}", inp) // [ᄌᄍᄎ]ᅧ → ᅥ
    }

    // 5.2
    static func ye(_ inp: String, _ descriptive: Bool = false) -> String {
        guard descriptive else { return inp }
        return RE.sub("([\u{1100}\u{1101}\u{1103}\u{1104}\u{11AF}\u{1106}\u{1107}\u{1108}\u{110C}\u{110D}\u{110E}\u{110F}\u{1110}\u{1111}\u{1112}])\u{1168}", "$1\u{1166}", inp)
    }

    // 5.3
    static func consonantUi(_ inp: String, _ descriptive: Bool = false) -> String {
        RE.sub("([\u{1100}\u{1101}\u{1102}\u{1103}\u{1104}\u{1105}\u{1106}\u{1107}\u{1108}\u{1109}\u{110A}\u{110C}\u{110D}\u{110E}\u{110F}\u{1110}\u{1111}\u{1112}])\u{1174}", "$1\u{1175}", inp) // C+ᅴ → ᅵ
    }

    // 5.4.2
    static func josaUi(_ inp: String, _ descriptive: Bool = false) -> String {
        if descriptive {
            return RE.sub("([^^])\u{C758}/J", "$1\u{C5D0}", inp) // (.)의/J → 에
        }
        return inp.replacingOccurrences(of: "/J", with: "")
    }

    // 5.4.1
    static func vowelUi(_ inp: String, _ descriptive: Bool = false) -> String {
        guard descriptive else { return inp }
        return RE.sub("([^^\\s]\u{110B})\u{1174}", "$1\u{1175}", inp)
    }

    // 16
    static func jamo(_ inp: String, _ descriptive: Bool = false) -> String {
        var out = inp
        out = RE.sub("(\u{B514}\u{ADF8})\u{11AE}\u{110B}", "$1\u{1109}", out)
        out = RE.sub("([\u{110C}\u{110E}\u{1110}\u{1112}]\u{1175}\u{C73C})[\u{11BD}\u{11BE}\u{11C0}\u{11C2}]\u{110B}", "$1\u{1109}", out)
        out = RE.sub("(\u{D0A4}\u{C73C})\u{11BF}\u{110B}", "$1\u{1100}", out)
        out = RE.sub("(\u{D53C}\u{C73C})\u{11C1}\u{110B}", "$1\u{1107}", out)
        return out
    }

    // 11.1
    static func rieulgiyeok(_ inp: String, _ descriptive: Bool = false) -> String {
        RE.sub("\u{11B0}/P([\u{1100}\u{1101}])", "\u{11AF}\u{1101}", inp)
    }

    // 25
    static func rieulbieub(_ inp: String, _ descriptive: Bool = false) -> String {
        var out = inp
        out = RE.sub("([\u{11B2}\u{11B4}])/P\u{1100}", "$1\u{1101}", out)
        out = RE.sub("([\u{11B2}\u{11B4}])/P\u{1103}", "$1\u{1104}", out)
        out = RE.sub("([\u{11B2}\u{11B4}])/P\u{1109}", "$1\u{110A}", out)
        out = RE.sub("([\u{11B2}\u{11B4}])/P\u{110C}", "$1\u{110D}", out)
        return out
    }

    // 24
    static func verbNieun(_ inp: String, _ descriptive: Bool = false) -> String {
        var out = inp
        let pairs: [(String, String)] = [
            ("([\u{11AB}\u{11B7}])/P\u{1100}", "$1\u{1101}"),
            ("([\u{11AB}\u{11B7}])/P\u{1103}", "$1\u{1104}"),
            ("([\u{11AB}\u{11B7}])/P\u{1109}", "$1\u{110A}"),
            ("([\u{11AB}\u{11B7}])/P\u{110C}", "$1\u{110D}"),
            ("\u{11AC}/P\u{1100}", "\u{11AB}\u{1101}"),
            ("\u{11AC}/P\u{1103}", "\u{11AB}\u{1104}"),
            ("\u{11AC}/P\u{1109}", "\u{11AB}\u{110A}"),
            ("\u{11AC}/P\u{110C}", "\u{11AB}\u{110D}"),
            ("\u{11B1}/P\u{1100}", "\u{11B7}\u{1101}"),
            ("\u{11B1}/P\u{1103}", "\u{11B7}\u{1104}"),
            ("\u{11B1}/P\u{1109}", "\u{11B7}\u{110A}"),
            ("\u{11B1}/P\u{110C}", "\u{11B7}\u{110D}"),
        ]
        for (p, r) in pairs { out = RE.sub(p, r, out) }
        return out
    }

    // 10.1
    static func balb(_ inp: String, _ descriptive: Bool = false) -> String {
        var out = inp
        let sfc = "($|[^\u{110B}\u{1112}])"
        out = RE.sub("(\u{BC14})\u{11B2}\(sfc)", "$1\u{11B8}$2", out)
        out = RE.sub("(\u{B108})\u{11B2}([\u{110C}\u{110D}]\u{116E}|[\u{1103}\u{1104}]\u{116E})", "$1\u{11B8}$2", out)
        return out
    }

    // 17
    static func palatalize(_ inp: String, _ descriptive: Bool = false) -> String {
        var out = inp
        out = RE.sub("\u{11AE}\u{110B}([\u{1175}\u{1167}])", "\u{110C}$1", out)
        out = RE.sub("\u{11C0}\u{110B}([\u{1175}\u{1167}])", "\u{110E}$1", out)
        out = RE.sub("\u{11B4}\u{110B}([\u{1175}\u{1167}])", "\u{11AF}\u{110E}$1", out)
        out = RE.sub("\u{11AE}\u{1112}([\u{1175}])", "\u{110E}$1", out)
        return out
    }

    // 27
    static func modifyingRieul(_ inp: String, _ descriptive: Bool = false) -> String {
        var out = inp
        let pairs: [(String, String)] = [
            ("\u{11AF}\u{AC78}", "\u{11AF}\u{AEC4}"),
            ("\u{11AF}\u{BC16}\u{C5D0}", "\u{11AF}\u{BE60}\u{AED4}"),
            ("\u{11AF}\u{C138}\u{B77C}", "\u{11AF}\u{C194}\u{B77C}"),
            ("\u{11AF}\u{C218}\u{B85D}", "\u{11AF}\u{C290}\u{B85D}"),
            ("\u{11AF}\u{C9C0}\u{B77C}\u{B3C4}", "\u{11AF}\u{C9C0}\u{B77C}\u{B3C4}"),
            ("\u{11AF}\u{C9C0}\u{C5B8}\u{C815}", "\u{11AF}\u{CC0C}\u{C5B8}\u{C815}"),
            ("\u{11AF}\u{C9C4}\u{B300}", "\u{11AF}\u{CC10}\u{B300}"),
        ]
        for (p, r) in pairs { out = RE.sub(p, r, out) }
        return out
    }
}
