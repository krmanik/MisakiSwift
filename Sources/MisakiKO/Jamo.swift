import Foundation

/// Hangul jamo decomposition / composition.
/// Pure-Swift replacement for the Python `jamo` package (h2j / j2h).
///
/// Works on CONJOINING jamo (the forms the g2pk regex rules target):
///   choseong  (initial)  U+1100…U+1112
///   jungseong (medial)   U+1161…U+1175
///   jongseong (final)    U+11A8…U+11C2
enum Jamo {

    // Conjoining jamo block bases (Unicode Hangul algorithm).
    static let sBase: UInt32 = 0xAC00   // '가'
    static let lBase: UInt32 = 0x1100   // choseong base
    static let vBase: UInt32 = 0x1161   // jungseong base
    static let tBase: UInt32 = 0x11A7   // jongseong base (index 0 = no final)
    static let lCount: UInt32 = 19
    static let vCount: UInt32 = 21
    static let tCount: UInt32 = 28
    static let nCount: UInt32 = vCount * tCount   // 588
    static let sCount: UInt32 = lCount * nCount   // 11172

    static func isSyllable(_ s: Unicode.Scalar) -> Bool {
        s.value >= sBase && s.value < sBase + sCount
    }

    static func isChoseong(_ s: Unicode.Scalar) -> Bool { (0x1100...0x1112).contains(s.value) }
    static func isJungseong(_ s: Unicode.Scalar) -> Bool { (0x1161...0x1175).contains(s.value) }
    static func isJongseong(_ s: Unicode.Scalar) -> Bool { (0x11A8...0x11C2).contains(s.value) }

    /// Decompose Hangul syllables in a string to conjoining jamo (mirrors `jamo.h2j`).
    /// Non-syllable scalars pass through unchanged.
    static func h2j(_ string: String) -> String {
        var out = String.UnicodeScalarView()
        for s in string.unicodeScalars {
            if isSyllable(s) {
                let sIndex = s.value - sBase
                let l = lBase + sIndex / nCount
                let v = vBase + (sIndex % nCount) / tCount
                let t = sIndex % tCount
                out.append(Unicode.Scalar(l)!)
                out.append(Unicode.Scalar(v)!)
                if t != 0 { out.append(Unicode.Scalar(tBase + t)!) }
            } else {
                out.append(s)
            }
        }
        return String(out)
    }

    /// Compose a single syllable from conjoining jamo scalars (mirrors `jamo.j2h`).
    /// `cho`, `jung` required; `jong` optional. Returns nil if indices invalid.
    static func j2h(_ cho: Unicode.Scalar, _ jung: Unicode.Scalar, _ jong: Unicode.Scalar? = nil) -> Character? {
        guard isChoseong(cho), isJungseong(jung) else { return nil }
        let lIndex = cho.value - lBase
        let vIndex = jung.value - vBase
        var tIndex: UInt32 = 0
        if let jong {
            guard isJongseong(jong) else { return nil }
            tIndex = jong.value - tBase
        }
        let code = sBase + (lIndex * vCount + vIndex) * tCount + tIndex
        return Character(Unicode.Scalar(code)!)
    }
}
