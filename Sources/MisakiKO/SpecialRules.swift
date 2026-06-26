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

    // 5.2  (char class uses ㄹ compatibility jamo U+3139, exactly as in g2pk)
    static func ye(_ inp: String, _ descriptive: Bool = false) -> String {
        guard descriptive else { return inp }
        return RE.sub("([\u{1100}\u{1101}\u{1103}\u{1104}\u{3139}\u{1106}\u{1107}\u{1108}\u{110C}\u{110D}\u{110E}\u{110F}\u{1110}\u{1111}\u{1112}])\u{1168}", "$1\u{1166}", inp)
    }

    // 5.3
    static func consonantUi(_ inp: String, _ descriptive: Bool = false) -> String {
        RE.sub("([\u{1100}\u{1101}\u{1102}\u{1103}\u{1104}\u{1105}\u{1106}\u{1107}\u{1108}\u{1109}\u{110A}\u{110C}\u{110D}\u{110E}\u{110F}\u{1110}\u{1111}\u{1112}])\u{1174}", "$1\u{1175}", inp) // C+ᅴ → ᅵ
    }

    // 5.4.2
    static func josaUi(_ inp: String, _ descriptive: Bool = false) -> String {
        if descriptive {
            // (.)의/J → 에 — 의/에 are conjoining jamo (의 → 에) at this stage.
            return RE.sub("([^^])\u{110B}\u{1174}/J", "$1\u{110B}\u{1166}", inp)
        }
        return inp.replacingOccurrences(of: "/J", with: "")
    }

    // 5.4.1
    static func vowelUi(_ inp: String, _ descriptive: Bool = false) -> String {
        guard descriptive else { return inp }
        return RE.sub("([^^\\s]\u{110B})\u{1174}", "$1\u{1175}", inp)
    }

    // 16  (patterns are decomposed conjoining jamo, matching g2pk exactly)
    static func jamo(_ inp: String, _ descriptive: Bool = false) -> String {
        var out = inp
        // (디그)ᆮᄋ → ᄉ
        out = RE.sub("(\u{1103}\u{1175}\u{1100}\u{1173})\u{11AE}\u{110B}", "$1\u{1109}", out)
        // ([ᄌᄎᄐᄒ]ᅵ으)[ᆽᆾᇀᇂ]ᄋ → ᄉ
        out = RE.sub("([\u{110C}\u{110E}\u{1110}\u{1112}]\u{1175}\u{110B}\u{1173})[\u{11BD}\u{11BE}\u{11C0}\u{11C2}]\u{110B}", "$1\u{1109}", out)
        // (키으)ᆿᄋ → ᄀ
        out = RE.sub("(\u{110F}\u{1175}\u{110B}\u{1173})\u{11BF}\u{110B}", "$1\u{1100}", out)
        // (피으)ᇁᄋ → ᄇ
        out = RE.sub("(\u{1111}\u{1175}\u{110B}\u{1173})\u{11C1}\u{110B}", "$1\u{1107}", out)
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

    // 10.1  (바/너 are decomposed conjoining jamo here)
    static func balb(_ inp: String, _ descriptive: Bool = false) -> String {
        var out = inp
        let sfc = "($|[^\u{110B}\u{1112}])"
        // (바)ᆲ(sfc) → ᆸ
        out = RE.sub("(\u{1107}\u{1161})\u{11B2}\(sfc)", "$1\u{11B8}$2", out)
        // (너)ᆲ([ᄌᄍ]ᅮ|[ᄃᄄ]ᅮ) → ᆸ
        out = RE.sub("(\u{1102}\u{1165})\u{11B2}([\u{110C}\u{110D}]\u{116E}|[\u{1103}\u{1104}]\u{116E})", "$1\u{11B8}$2", out)
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

    // 27  (decomposed conjoining jamo, matching g2pk exactly)
    static func modifyingRieul(_ inp: String, _ descriptive: Bool = false) -> String {
        var out = inp
        let pairs: [(String, String)] = [
            // ᆯ걸 → ᆯ껄
            ("\u{11AF}\u{1100}\u{1165}\u{11AF}", "\u{11AF}\u{1101}\u{1165}\u{11AF}"),
            // ᆯ밖에 → ᆯ빠께
            ("\u{11AF}\u{1107}\u{1161}\u{11A9}\u{110B}\u{1166}", "\u{11AF}\u{1108}\u{1161}\u{1101}\u{1166}"),
            // ᆯ세라 → ᆯ쎄라
            ("\u{11AF}\u{1109}\u{1166}\u{1105}\u{1161}", "\u{11AF}\u{110A}\u{1166}\u{1105}\u{1161}"),
            // ᆯ수록 → ᆯ쑤록
            ("\u{11AF}\u{1109}\u{116E}\u{1105}\u{1169}\u{11A8}", "\u{11AF}\u{110A}\u{116E}\u{1105}\u{1169}\u{11A8}"),
            // ᆯ지라도 → ᆯ찌라도
            ("\u{11AF}\u{110C}\u{1175}\u{1105}\u{1161}\u{1103}\u{1169}", "\u{11AF}\u{110D}\u{1175}\u{1105}\u{1161}\u{1103}\u{1169}"),
            // ᆯ지언정 → ᆯ찌언정
            ("\u{11AF}\u{110C}\u{1175}\u{110B}\u{1165}\u{11AB}\u{110C}\u{1165}\u{11BC}", "\u{11AF}\u{110D}\u{1175}\u{110B}\u{1165}\u{11AB}\u{110C}\u{1165}\u{11BC}"),
            // ᆯ진대 → ᆯ찐대
            ("\u{11AF}\u{110C}\u{1175}\u{11AB}\u{1103}\u{1162}", "\u{11AF}\u{110D}\u{1175}\u{11AB}\u{1103}\u{1162}"),
        ]
        for (p, r) in pairs { out = RE.sub(p, r, out) }
        return out
    }
}
