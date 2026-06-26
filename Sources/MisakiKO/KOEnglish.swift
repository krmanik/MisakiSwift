import Foundation

/// Full port of g2pkc/english.py + the English helpers in g2pkc/utils.py
/// (adjust / to_choseong / to_jungseong / to_jongseong / reconstruct).
/// Converts embedded English words to Hangul using CMUdict ARPAbet pronunciations,
/// falling back to letter-spelling for acronyms / out-of-vocabulary words.
enum KOEnglish {

    // MARK: - Letter spelling fallback (eng2kor)

    private static let eng2kor: [Character: String] = [
        "A": "에이", "B": "비", "C": "씨", "D": "디", "E": "이",
        "F": "에프", "G": "지", "H": "에이치", "I": "아이", "J": "제이",
        "K": "케이", "L": "엘", "M": "엠", "N": "엔", "O": "오",
        "P": "피", "Q": "큐", "R": "알", "S": "에스", "T": "티",
        "U": "유", "V": "브이", "W": "더블유", "X": "엑스", "Y": "와이", "Z": "지",
    ]

    static func wordToHangul(_ word: String) -> String {
        word.uppercased().compactMap { eng2kor[$0] }.joined()
    }

    // MARK: - CMUdict

    private static let cmu: [String: [String]] = loadCMUDict()

    private static func loadCMUDict() -> [String: [String]] {
        guard let url = Bundle.module.url(forResource: "cmudict", withExtension: "dict"),
              let raw = try? String(contentsOf: url, encoding: .utf8) else {
            return [:]
        }
        var dict: [String: [String]] = [:]
        for line in raw.components(separatedBy: .newlines) {
            if line.isEmpty { continue }
            // Strip inline "# comment".
            let noComment = line.components(separatedBy: " #").first ?? line
            let toks = noComment.split(separator: " ").map(String.init)
            guard let word = toks.first, !word.contains("(") else { continue } // skip variants "(2)"
            if dict[word] != nil { continue } // keep first occurrence == cmu[word][0]
            dict[word] = Array(toks.dropFirst())
        }
        return dict
    }

    // MARK: - ARPAbet → Hangul jamo maps (utils.py)

    // The maps below use exact codepoints from g2pkc/utils.py. Note diphthong
    // jungseong values embed a conjoining filler ᄋ(110B) + ᅵ(1175) etc — NOT
    // precomposed syllables — so compose() can attach a following jongseong.
    private static func toChoseong(_ p: String) -> String {
        let d: [String: String] = [
            "B": "\u{1107}", "CH": "\u{110E}", "D": "\u{1103}", "DH": "\u{1103}", "DZ": "\u{110C}", "F": "\u{1111}", "G": "\u{1100}", "HH": "\u{1112}", "JH": "\u{110C}", "K": "\u{110F}", "L": "\u{1105}", "M": "\u{1106}", "N": "\u{1102}", "NG": "\u{110B}", "P": "\u{1111}", "R": "\u{1105}", "S": "\u{1109}", "SH": "\u{1109}", "T": "\u{1110}", "TH": "\u{1109}", "TS": "\u{110E}", "V": "\u{1107}", "W": "\u{0057}", "Y": "\u{0059}", "Z": "\u{110C}", "ZH": "\u{110C}",
        ]
        return d[p] ?? p
    }

    private static func toJungseong(_ p: String) -> String {
        let d: [String: String] = [
            "AA": "\u{1161}", "AE": "\u{1162}", "AH": "\u{1165}", "AO": "\u{1169}", "AW": "\u{1161}\u{110B}\u{116E}", "AWER": "\u{1161}\u{110B}\u{116F}", "AY": "\u{1161}\u{110B}\u{1175}", "EH": "\u{1166}", "ER": "\u{1165}", "EY": "\u{1166}\u{110B}\u{1175}", "IH": "\u{1175}", "IY": "\u{1175}", "OW": "\u{1169}", "OY": "\u{1169}\u{110B}\u{1175}", "UH": "\u{116E}", "UW": "\u{116E}",
        ]
        return d[p] ?? p
    }

    private static func toJongseong(_ p: String) -> String {
        let d: [String: String] = [
            "B": "\u{11B8}", "CH": "\u{11BE}", "D": "\u{11AE}", "DH": "\u{11AE}", "F": "\u{11C1}", "G": "\u{11A8}", "HH": "\u{11C2}", "JH": "\u{11BD}", "K": "\u{11A8}", "L": "\u{11AF}", "M": "\u{11B7}", "N": "\u{11AB}", "NG": "\u{11BC}", "P": "\u{11B8}", "R": "\u{11AF}", "S": "\u{11BA}", "SH": "\u{11BA}", "T": "\u{11BA}", "TH": "\u{11BA}", "V": "\u{11B8}", "W": "\u{11BC}", "Y": "\u{11BC}", "Z": "\u{11BD}", "ZH": "\u{11BD}",
        ]
        return d[p] ?? p
    }

    /// Modify arpabets so they fit the per-phoneme rules (utils.adjust).
    private static func adjust(_ arpabets: [String]) -> [String] {
        var s = " " + arpabets.joined(separator: " ") + " $"
        s = RE.sub("[0-9]", "", s)                  // strip stress digits
        s = s.replacingOccurrences(of: " T S ", with: " TS ")
        s = s.replacingOccurrences(of: " D Z ", with: " DZ ")
        s = s.replacingOccurrences(of: " AW ER ", with: " AWER ")
        s = s.replacingOccurrences(of: " IH R $", with: " IH ER ")
        s = s.replacingOccurrences(of: " EH R $", with: " EH ER ")
        s = s.replacingOccurrences(of: " $", with: "")
        return s.trimmingCharacters(in: CharacterSet(charactersIn: "$ ")).split(separator: " ").map(String.init)
    }

    /// Postprocessing of placeholder W/Y semivowels (utils.reconstruct).
    private static func reconstruct(_ string: String) -> String {
        // Exact codepoints from utils.reconstruct. W/Y are ASCII placeholders
        // (U+0057/U+0059); embedded syllables are conjoining jamo.
        let pairs: [(String, String)] = [
            ("\u{1100}\u{1173}\u{0057}", "\u{1100}\u{0057}"),
            ("\u{1112}\u{1173}\u{0057}", "\u{1112}\u{0057}"),
            ("\u{110F}\u{1173}\u{0057}", "\u{110F}\u{0057}"),
            ("\u{1102}\u{0059}\u{1165}", "\u{1102}\u{1175}\u{110B}\u{1165}"),
            ("\u{1103}\u{0059}\u{1165}", "\u{1103}\u{1175}\u{110B}\u{1165}"),
            ("\u{1105}\u{0059}\u{1165}", "\u{1105}\u{1175}\u{110B}\u{1165}"),
            ("\u{0059}\u{1175}", "\u{1175}"),
            ("\u{0059}\u{1161}", "\u{1163}"),
            ("\u{0059}\u{1162}", "\u{1164}"),
            ("\u{0059}\u{1165}", "\u{1167}"),
            ("\u{0059}\u{1166}", "\u{1168}"),
            ("\u{0059}\u{1169}", "\u{116D}"),
            ("\u{0059}\u{116E}", "\u{1172}"),
            ("\u{0057}\u{1161}", "\u{116A}"),
            ("\u{0057}\u{1162}", "\u{116B}"),
            ("\u{0057}\u{1165}", "\u{116F}"),
            ("\u{0057}\u{1169}", "\u{116F}"),
            ("\u{0057}\u{116E}", "\u{116E}"),
            ("\u{0057}\u{1166}", "\u{1170}"),
            ("\u{0057}\u{1175}", "\u{1171}"),
            ("\u{1173}\u{1175}", "\u{1174}"),
            ("\u{0059}", "\u{1175}"),
            ("\u{0057}", "\u{116E}"),
        ]
        var out = string
        for (a, b) in pairs { out = out.replacingOccurrences(of: a, with: b, options: .literal) }
        return out
    }

    // MARK: - Main

    /// Replace English words in `string` with Hangul. Mirrors english.py convert_eng.
    static func convertEng(_ string: String) -> String {
        guard let regex = try? NSRegularExpression(pattern: "[A-Za-z]+") else { return string }
        let range = NSRange(string.startIndex..., in: string)
        var words = Set<String>()
        for m in regex.matches(in: string, range: range) {
            if let r = Range(m.range, in: string) { words.insert(String(string[r])) }
        }
        var result = string
        // Longest-first so substrings don't clobber.
        for engWord in words.sorted(by: { $0.count > $1.count }) {
            let lower = engWord.lowercased()
            let isUpper = engWord == engWord.uppercased() && engWord.contains { $0.isLetter }

            if isUpper || cmu[lower] == nil {
                result = result.replacingOccurrences(of: engWord, with: wordToHangul(engWord))
                continue
            }

            let phonemes = adjust(cmu[lower]!)
            var ret = ""
            for i in 0..<phonemes.count {
                let p = phonemes[i]
                let pPrev = i > 0 ? phonemes[i - 1] : "^"
                let pNext = i < phonemes.count - 1 ? phonemes[i + 1] : "$"
                let pNext2 = i < phonemes.count - 2 ? phonemes[i + 1] : "$"

                let shortVowels: Set<String> = ["AE", "AH", "AX", "EH", "IH", "IX", "UH"]
                let vowels = "AEIOUY"
                let consonants = "BCDFGHJKLMNPQRSTVWXZ"
                let sfc = "$BCDFGHJKLMNPQRSTVWXZ"           // syllable_final_or_consonants
                func first(_ s: String) -> Character { s.first ?? "$" }
                func prefix2(_ s: String) -> String { String(s.prefix(2)) }

                if "PTK".contains(p) {
                    if shortVowels.contains(prefix2(pPrev)) && pNext == "$" {
                        ret += toJongseong(p)
                    } else if shortVowels.contains(prefix2(pPrev)) && !"AEIOULRMN".contains(first(pNext)) {
                        ret += toJongseong(p)
                    } else if "$BCDFGHJKLMNPQRSTVWXYZ".contains(first(pNext)) {
                        ret += toChoseong(p); ret += "\u{1173}"
                    } else {
                        ret += toChoseong(p)
                    }
                } else if "BDG".contains(p) {
                    ret += toChoseong(p)
                    if sfc.contains(first(pNext)) { ret += "\u{1173}" }
                } else if ["S", "Z", "F", "V", "TH", "DH", "SH", "ZH"].contains(p) {
                    ret += toChoseong(p)
                    if ["S", "Z", "F", "V", "TH", "DH"].contains(p) {
                        if sfc.contains(first(pNext)) { ret += "\u{1173}" }
                    } else if p == "SH" {
                        if first(pNext) == "$" { ret += "\u{1175}" }
                        else if consonants.contains(first(pNext)) { ret += "\u{1172}" }
                        else { ret += "Y" }
                    } else if p == "ZH" {
                        if sfc.contains(first(pNext)) { ret += "\u{1175}" }
                    }
                } else if ["TS", "DZ", "CH", "JH"].contains(p) {
                    ret += toChoseong(p)
                    if sfc.contains(first(pNext)) {
                        ret += (p == "TS" || p == "DZ") ? "\u{1173}" : "\u{1175}"
                    }
                } else if ["M", "N", "NG"].contains(p) {
                    if (p == "M" || p == "N") && vowels.contains(first(pNext)) {
                        ret += toChoseong(p)
                    } else {
                        ret += toJongseong(p)
                    }
                } else if p == "L" {
                    if pPrev == "^" {
                        ret += toChoseong(p)
                    } else if "$BCDFGHJKLPQRSTVWXZ".contains(first(pNext)) {
                        ret += toJongseong(p)
                    } else if pPrev == "M" || pPrev == "N" {
                        ret += toChoseong(p)
                    } else if vowels.contains(first(pNext)) {
                        ret += "\u{11AF}\u{1105}"
                    } else if (pNext == "M" || pNext == "N") && !vowels.contains(first(pNext2)) {
                        ret += "\u{11AF}르"
                    }
                } else if p == "ER" {
                    if vowels.contains(first(pPrev)) { ret += "\u{110B}" }
                    ret += toJungseong(p)
                    if vowels.contains(first(pNext)) { ret += "\u{1105}" }
                } else if p == "R" {
                    if vowels.contains(first(pNext)) { ret += toChoseong(p) }
                } else if "AEIOU".contains(first(p)) {
                    ret += toJungseong(p)
                } else {
                    ret += toChoseong(p)
                }
            }

            ret = reconstruct(ret)
            ret = KOUtils.compose(ret)
            ret = RE.sub("[\u{1100}-\u{11FF}]", "", ret) // remove leftover jamo
            result = result.replacingOccurrences(of: engWord, with: ret)
        }
        return result
    }
}
