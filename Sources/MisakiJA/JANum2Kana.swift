import Foundation

/// Port of misaki's num2kana.py (Greatdane/Convert-Numbers-to-Japanese, MIT).
/// Converts arabic numbers to Japanese (hiragana / kanji / romaji), and kanji
/// numbers back to arabic. Works up to 9 digits, like the original.
public enum JANum2Kana {

    public enum Script: String { case kanji, hiragana, romaji }

    private static let romaji: [String: String] = [
        ".": "ten", "0": "zero", "1": "ichi", "2": "ni", "3": "san", "4": "yon", "5": "go",
        "6": "roku", "7": "nana", "8": "hachi", "9": "kyuu", "10": "juu", "100": "hyaku",
        "1000": "sen", "10000": "man", "100000000": "oku", "300": "sanbyaku", "600": "roppyaku",
        "800": "happyaku", "3000": "sanzen", "8000": "hassen", "01000": "issen",
    ]
    private static let kanji: [String: String] = [
        ".": "点", "0": "零", "1": "一", "2": "二", "3": "三", "4": "四", "5": "五", "6": "六",
        "7": "七", "8": "八", "9": "九", "10": "十", "100": "百", "1000": "千", "10000": "万",
        "100000000": "億", "300": "三百", "600": "六百", "800": "八百", "3000": "三千",
        "8000": "八千", "01000": "一千",
    ]
    private static let hiragana: [String: String] = [
        ".": "てん", "0": "ゼロ", "1": "いち", "2": "に", "3": "さん", "4": "よん", "5": "ご",
        "6": "ろく", "7": "なな", "8": "はち", "9": "きゅう", "10": "じゅう", "100": "ひゃく",
        "1000": "せん", "10000": "まん", "100000000": "おく", "300": "さんびゃく",
        "600": "ろっぴゃく", "800": "はっぴゃく", "3000": "さんぜん", "8000": "はっせん",
        "01000": "いっせん",
    ]

    private static func dict(_ s: Script) -> [String: String] {
        switch s { case .kanji: return kanji; case .hiragana: return hiragana; case .romaji: return romaji }
    }

    private static func ch(_ s: String, _ i: Int) -> String {
        let arr = Array(s); return i >= 0 && i < arr.count ? String(arr[i]) : ""
    }

    private static func lenOne(_ n: String, _ d: [String: String]) -> String { d[n] ?? "" }

    private static func lenTwo(_ n: String, _ d: [String: String]) -> String {
        if ch(n, 0) == "0" { return lenOne(ch(n, 1), d) }
        if n == "10" { return d["10"]! }
        if ch(n, 0) == "1" { return d["10"]! + " " + lenOne(ch(n, 1), d) }
        if ch(n, 1) == "0" { return lenOne(ch(n, 0), d) + " " + d["10"]! }
        var parts = Array(n).map { d[String($0)] ?? "" }
        parts.insert(d["10"]!, at: 1)
        return parts.joined(separator: " ")
    }

    private static func lenThree(_ n: String, _ d: [String: String]) -> String {
        var list: [String] = []
        switch ch(n, 0) {
        case "1": list.append(d["100"]!)
        case "3": list.append(d["300"]!)
        case "6": list.append(d["600"]!)
        case "8": list.append(d["800"]!)
        default: list.append(d[ch(n, 0)] ?? ""); list.append(d["100"]!)
        }
        let tail = String(Array(n)[1...].map { $0 })
        if !(tail == "00" && n.count == 3) {
            if ch(n, 1) == "0" { list.append(d[ch(n, 2)] ?? "") }
            else { list.append(lenTwo(tail, d)) }
        }
        return list.joined(separator: " ")
    }

    private static func lenFour(_ rawN: String, _ d: [String: String], _ standAlone: Bool) -> String {
        var n = rawN
        if n == "0000" { return "" }
        while ch(n, 0) == "0" { n = String(n.dropFirst()) }
        if n.count == 1 { return lenOne(n, d) }
        if n.count == 2 { return lenTwo(n, d) }
        if n.count == 3 { return lenThree(n, d) }
        var list: [String] = []
        switch ch(n, 0) {
        case "1": list.append(d[standAlone ? "1000" : "01000"]!)
        case "3": list.append(d["3000"]!)
        case "8": list.append(d["8000"]!)
        default: list.append(d[ch(n, 0)] ?? ""); list.append(d["1000"]!)
        }
        let tail = String(Array(n)[1...].map { $0 })
        if !(tail == "000" && n.count == 4) {
            if ch(n, 1) == "0" { list.append(lenTwo(String(Array(n)[2...].map { $0 }), d)) }
            else { list.append(lenThree(tail, d)) }
        }
        return list.joined(separator: " ")
    }

    private static func lenX(_ n: String, _ d: [String: String]) -> String {
        var list: [String] = []
        let head = String(Array(n).dropLast(4))
        switch head.count {
        case 1:
            list.append(d[head] ?? ""); list.append(d["10000"]!)
        case 2:
            list.append(lenTwo(String(Array(n)[0..<2].map { $0 }), d)); list.append(d["10000"]!)
        case 3:
            list.append(lenThree(String(Array(n)[0..<3].map { $0 }), d)); list.append(d["10000"]!)
        case 4:
            list.append(lenFour(String(Array(n)[0..<4].map { $0 }), d, false)); list.append(d["10000"]!)
        case 5:
            list.append(d[ch(n, 0)] ?? ""); list.append(d["100000000"]!)
            list.append(lenFour(String(Array(n)[1..<5].map { $0 }), d, false))
            if String(Array(n)[1..<5].map { $0 }) != "0000" { list.append(d["10000"]!) }
        default:
            return "" // matches the original's assert (>9 digits handled by caller)
        }
        list.append(lenFour(String(Array(n).suffix(4)), d, false))
        return list.joined(separator: " ")
    }

    private static func removeSpaces(_ s: String) -> String { s.replacingOccurrences(of: " ", with: "") }

    private static func doConvert(_ n: String, _ d: [String: String]) -> String {
        switch n.count {
        case 1: return lenOne(n, d)
        case 2: return lenTwo(n, d)
        case 3: return lenThree(n, d)
        case 4: return lenFour(n, d, true)
        default: return lenX(n, d)
        }
    }

    private static func splitPoint(_ num: String, _ script: Script) -> String {
        let d = dict(script)
        let parts = num.components(separatedBy: ".")
        let a = parts[0], b = parts.count > 1 ? parts[1] : ""
        var bEnd = " "
        for x in b { bEnd += lenOne(String(x), d) + " " }
        let aArr = Array(a)
        if aArr.last == "0", aArr.count >= 2, aArr[aArr.count - 2] != "0", script == .hiragana {
            var smallTsu = convert(a, script)
            smallTsu = String(smallTsu.dropLast()) + "っ"
            return smallTsu + d["."]! + bEnd
        }
        if aArr.last == "0", aArr.count >= 2, aArr[aArr.count - 2] != "0", script == .romaji {
            var smallTsu = convert(a, script)
            smallTsu = String(smallTsu.dropLast()) + "t"
            return smallTsu + d["."]! + bEnd
        }
        return convert(a, script) + " " + d["."]! + bEnd
    }

    /// Convert an arabic number string to Japanese. Returns the original-style
    /// error string if longer than 9 digits, matching num2kana.py.
    public static func convert(_ rawNum: String, _ script: Script = .hiragana) -> String {
        var num = rawNum.replacingOccurrences(of: ",", with: "")
        if num.count > 9 { return "Number length too long, choose less than 10 digits" }
        while ch(num, 0) == "0" && num.count > 1 { num = String(num.dropFirst()) }

        let result: String
        if num.contains(".") {
            result = splitPoint(num, script)
        } else {
            result = doConvert(num, dict(script))
        }
        return script == .romaji ? result : removeSpaces(result)
    }

    // MARK: - Reverse: kanji number → arabic (do_kanji_convert / ConvertKanji)

    private static func doKanjiConvert(_ num: String) -> Int {
        if num == "零" { return 0 }
        var key: [String] = []
        var numberList: [String] = []
        var y = ""
        for x in num {
            let xs = String(x)
            if xs == "万" || xs == "億" {
                numberList.append(y); key.append("times")
                numberList.append(xs); key.append("plus")
                y = ""
            } else { y += xs }
        }
        if !y.isEmpty { numberList.append(y) }

        let baseNumber = Set(["一", "二", "三", "四", "五", "六", "七", "八", "九"])
        let linkNumber = Set(["十", "百", "千", "万", "億"])
        func kanjiToInt(_ k: String) -> Int? {
            for (key, val) in kanji where val == k { return Int(key) }
            return nil
        }

        var converted: [Int] = []
        for noX in numberList {
            let chars = Array(noX)
            var count = chars.count
            var result = 0
            var skip = 1
            for x in chars.reversed() {
                let xs = String(x)
                var addTo = 0
                skip -= 1
                count -= 1
                if skip == 1 { continue }
                if baseNumber.contains(xs) {
                    if let v = kanjiToInt(xs) { result += v }
                } else if linkNumber.contains(xs) {
                    if count >= 0 && count - 1 >= 0 && baseNumber.contains(String(chars[count - 1])) {
                        if let temp = kanjiToInt(String(chars[count - 1])), let mul = kanjiToInt(xs) {
                            addTo += temp * mul
                            result += addTo
                            skip = 2
                        }
                    } else {
                        if let v = kanjiToInt(xs) { result += v }
                    }
                }
            }
            converted.append(result)
        }

        guard var result = converted.first else { return 0 }
        var y2 = 0
        var x = 1
        while x < converted.count {
            if y2 < key.count && key[y2] == "plus" {
                if y2 + 1 < key.count && key[y2 + 1] == "times" && x + 1 < converted.count {
                    result += converted[x] * converted[x + 1]
                    y2 += 1
                } else if x < converted.count {
                    result += converted[x]
                } else {
                    result += converted.last!
                    break
                }
            } else {
                result *= converted[x]
            }
            y2 += 1
            x += 1
        }
        return result
    }

    /// Convert a kanji number to its arabic string (ConvertKanji), with 点 decimals.
    public static func convertKanji(_ num: String) -> String? {
        guard let first = num.first, kanji.values.contains(String(first)) else { return nil }
        if num.contains("点") {
            let comps = num.components(separatedBy: "点")
            let intPart = doKanjiConvert(comps[0])
            var endNumber = ""
            for x in comps.count > 1 ? comps[1] : "" {
                for (k, v) in kanji where v == String(x) { endNumber += k }
            }
            return "\(intPart).\(endNumber)"
        }
        return String(doKanjiConvert(num))
    }
}
