import Foundation

/// Regex helper mirroring Python `re.sub`.
/// Templates use `$1` (NSRegularExpression style); callers pass Python `\1` translated to `$1`.
enum RE {
    static func sub(_ pattern: String, _ template: String, _ input: String) -> String {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return input }
        let range = NSRange(input.startIndex..., in: input)
        return regex.stringByReplacingMatches(in: input, range: range, withTemplate: template)
    }
}

/// Ports of g2pkc/utils.py table parsing + Hangul (de)composition postprocessing.
enum KOUtils {

    /// Parse table.csv → list of (pattern, replacement, ruleIDs).
    /// Header row = onset columns; col 0 of each row = coda. Cell may carry "(rule/ids)".
    static func parseTable() -> [(String, String, [String])] {
        guard let url = Bundle.module.url(forResource: "table", withExtension: "csv"),
              let raw = try? String(contentsOf: url, encoding: .utf8) else {
            return []
        }
        // Strip BOM if present. Split on newlines via CharacterSet — note Swift fuses
        // "\r\n" into one grapheme, so split(separator:"\n") would miss CRLF lines.
        let text = raw.hasPrefix("\u{FEFF}") ? String(raw.dropFirst()) : raw
        let lines = text.components(separatedBy: .newlines)
        guard let header = lines.first else { return [] }
        let onsets = header.components(separatedBy: ",")

        var table: [(String, String, [String])] = []
        for line in lines.dropFirst() where !line.isEmpty {
            let cols = line.components(separatedBy: ",")
            guard let coda = cols.first else { continue }
            for i in 1..<onsets.count where i < cols.count {
                let cell = cols[i]
                if cell.isEmpty { continue }
                let onset = onsets[i]
                let str1 = coda + onset
                var str2 = cell
                var ruleIDs: [String] = []
                if let open = cell.firstIndex(of: "(") {
                    str2 = String(cell[..<open])
                    let inner = cell[cell.index(after: open)...].dropLast() // drop trailing ')'
                    ruleIDs = inner.components(separatedBy: "/")
                }
                // Translate Python backref "\1" → NSRegularExpression template "$1".
                str2 = str2.replacingOccurrences(of: "\\1", with: "$1")
                table.append((str1, str2, ruleIDs))
            }
        }
        return table
    }

    /// Reassemble conjoining jamo into syllables (mirrors utils.compose).
    static func compose(_ letters: String) -> String {
        // Insert filler ᄋ before a bare vowel (no preceding choseong).
        var string = RE.sub("(^|[^\u{1100}-\u{1112}])([\u{1161}-\u{1175}])", "$1\u{110B}$2", letters)

        // c+v+c
        string = recompose(string, pattern: "[\u{1100}-\u{1112}][\u{1161}-\u{1175}][\u{11A8}-\u{11C2}]")
        // c+v
        string = recompose(string, pattern: "[\u{1100}-\u{1112}][\u{1161}-\u{1175}]")
        return string
    }

    private static func recompose(_ string: String, pattern: String) -> String {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return string }
        let range = NSRange(string.startIndex..., in: string)
        var result = string
        var seen = Set<String>()
        for match in regex.matches(in: string, range: range) {
            guard let r = Range(match.range, in: string) else { continue }
            let syl = String(string[r])
            if seen.contains(syl) { continue }
            seen.insert(syl)
            let scalars = Array(syl.unicodeScalars)
            let jong = scalars.count == 3 ? scalars[2] : nil
            if let ch = Jamo.j2h(scalars[0], scalars[1], jong) {
                result = result.replacingOccurrences(of: syl, with: String(ch), options: .literal)
            }
        }
        return result
    }

    /// group_vowels=True merging (mirrors utils.group). Unused by default pipeline.
    static func group(_ inp: String) -> String {
        var out = inp
        out = out.replacingOccurrences(of: "\u{1162}", with: "\u{1166}", options: .literal) // ᅢ→ᅦ
        out = out.replacingOccurrences(of: "\u{1164}", with: "\u{1168}", options: .literal) // ᅤ→ᅨ
        out = out.replacingOccurrences(of: "\u{116B}", with: "\u{116C}", options: .literal) // ᅫ→ᅬ
        out = out.replacingOccurrences(of: "\u{1170}", with: "\u{116C}", options: .literal) // ᅰ→ᅬ
        return out
    }
}
