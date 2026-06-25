import Foundation

/// Port of g2pkc/numerals.py — spell out arabic numerals in Korean.
enum KONumerals {

    /// Bound nouns that take native-Korean (non-sino) numerals.
    static let boundNouns: Set<String> = Set(
        "군데 권 개 그루 닢 두 마리 모 모금 뭇 발 발짝 방 번 벌 보루 살 수 술 시 쌈 움큼 정 짝 채 척 첩 축 켤레 톨 통 가지 배 시간 살 명 줄 곳"
            .split(separator: " ").map(String.init)
    )

    private static let digits = Array("123456789")
    private static let names = Array("일이삼사오육칠팔구")
    private static let modifiers = "한 두 세 네 다섯 ^여섯 일곱 ^여덟 아홉".split(separator: " ").map(String.init)
    private static let decimals = "열 스물 서른 마흔 쉰 예순 일흔 여든 아흔".split(separator: " ").map(String.init)

    private static func digit2name(_ d: Character) -> String {
        guard let idx = digits.firstIndex(of: d) else { return "" }
        return "^" + String(names[idx])
    }
    private static func digit2mod(_ d: Character) -> String {
        guard let idx = digits.firstIndex(of: d) else { return "" }
        return modifiers[idx]
    }
    private static func digit2dec(_ d: Character) -> String {
        guard let idx = digits.firstIndex(of: d) else { return "" }
        return decimals[idx]
    }

    /// Spell out a pure-digit string. `sino`=false uses native modifying forms.
    static func processNum(_ rawNum: String, sino: Bool) -> String {
        let num = rawNum.replacingOccurrences(of: ",", with: "")
        if num == "0" { return "영" }
        if !sino && num == "20" { return "스무" }

        let chars = Array(num)
        let len = chars.count
        var spelledOut: [String] = []

        for (idx, digit) in chars.enumerated() {
            let i = len - idx - 1   // position from the right
            var name = ""

            if sino || len >= 3 {
                if i == 0 { name = digit2name(digit) }
                else if i == 1 { name = (digit2name(digit) + "십").replacingOccurrences(of: "일십", with: "십") }
            } else {
                if i == 0 { name = digit2mod(digit) }
                else if i == 1 { name = digit2dec(digit) }
            }

            if digit == "0" {
                if i % 4 == 0 {
                    let lastThree = spelledOut.suffix(min(3, spelledOut.count)).joined()
                    if lastThree.isEmpty { spelledOut.append(""); continue }
                } else {
                    spelledOut.append(""); continue
                }
            }

            switch i {
            case 2:  name = (digit2name(digit) + "백").replacingOccurrences(of: "일백", with: "백")
            case 3:  name = (digit2name(digit) + "천").replacingOccurrences(of: "일천", with: "천")
            case 4:  name = (digit2name(digit) + "만").replacingOccurrences(of: "일만", with: "만")
            case 5:  name = (digit2name(digit) + "십").replacingOccurrences(of: "일십", with: "십")
            case 6:  name = (digit2name(digit) + "백").replacingOccurrences(of: "일백", with: "백")
            case 7:  name = (digit2name(digit) + "천").replacingOccurrences(of: "일천", with: "천")
            case 8:  name = digit2name(digit) + "억"
            case 9:  name = digit2name(digit) + "십"
            case 10: name = digit2name(digit) + "백"
            case 11: name = digit2name(digit) + "천"
            case 12: name = digit2name(digit) + "조"
            case 13: name = digit2name(digit) + "십"
            case 14: name = digit2name(digit) + "백"
            case 15: name = digit2name(digit) + "천"
            default: break
            }
            spelledOut.append(name)
        }
        return spelledOut.joined()
    }

    /// Convert arabic numerals in an annotated string to spelled-out Korean.
    static func convertNum(_ string: String) -> String {
        var result = string
        let pattern = "([0-9][0-9,]*)( ?[\u{AC00}-\u{D7A3}]+)?(?:/B)?"
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return string }
        let range = NSRange(string.startIndex..., in: string)

        // Collect unique (num, bn) pairs, longest-first to avoid partial clobbering.
        var seen = Set<String>()
        var tokens: [(num: String, bn: String)] = []
        for m in regex.matches(in: string, range: range) {
            guard let numR = Range(m.range(at: 1), in: string) else { continue }
            let num = String(string[numR])
            var bn = ""
            if m.range(at: 2).location != NSNotFound, let bnR = Range(m.range(at: 2), in: string) {
                bn = String(string[bnR])
            }
            let key = num + "\u{0}" + bn
            if seen.insert(key).inserted { tokens.append((num, bn)) }
        }
        tokens.sort { ($0.num.count + $0.bn.count) > ($1.num.count + $1.bn.count) }

        for (num, bn) in tokens {
            let bnTrimmed = bn.drop { $0 == " " }
            let bnStr = String(bnTrimmed)
            let spelled = processNum(num, sino: !boundNouns.contains(bnStr))
            result = result.replacingOccurrences(of: num + bn, with: spelled + bnStr)
        }

        // Digit-by-digit for any remaining digits.
        let dchars = Array("0123456789")
        let dnames = Array("영일이삼사오육칠팔구")
        for (d, n) in zip(dchars, dnames) {
            result = result.replacingOccurrences(of: String(d), with: "^" + String(n))
        }
        result = result.replacingOccurrences(of: "십^육", with: "심뉵")
        result = result.replacingOccurrences(of: "백^육", with: "뱅뉵")
        return result
    }
}
