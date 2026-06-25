import Foundation

/// Port of g2pkc/english.py — convert embedded English words to Hangul.
///
/// v0: implements only the letter-spelling fallback (the `isupper || OOV` branch),
/// which covers acronyms and out-of-vocabulary words. The full ARPAbet path
/// (cmudict + adjust/to_choseong/to_jungseong/to_jongseong/reconstruct) is TODO —
/// it requires bundling cmudict and porting english.py's per-phoneme rules.
enum KOEnglish {

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

    /// Replace English words in `string` with their Hangul spelling.
    static func convertEng(_ string: String) -> String {
        guard let regex = try? NSRegularExpression(pattern: "[A-Za-z]+") else { return string }
        let range = NSRange(string.startIndex..., in: string)
        var words = Set<String>()
        for m in regex.matches(in: string, range: range) {
            if let r = Range(m.range, in: string) { words.insert(String(string[r])) }
        }
        var result = string
        // Longest-first so substrings don't clobber.
        for word in words.sorted(by: { $0.count > $1.count }) {
            result = result.replacingOccurrences(of: word, with: wordToHangul(word))
        }
        return result
    }
}
