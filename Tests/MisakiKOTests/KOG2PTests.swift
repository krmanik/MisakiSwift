import XCTest
@testable import MisakiKO

final class KOG2PTests: XCTestCase {

    func testJamoRoundTrip() {
        let s = "학교"
        let decomposed = Jamo.h2j(s)
        XCTAssertEqual(decomposed.unicodeScalars.count, 5) // 학 + 교
        // recompose
        let composed = KOUtils.compose(decomposed)
        XCTAssertEqual(composed, s)
    }

    func testSmoke() {
        let g = KOG2P()
        let cases = ["안녕하세요", "학교", "좋다", "맑다", "3개를", "값이"]
        for t in cases {
            let out = g.phonemize(t, toSyllable: true)
            print("KO: \(t) -> \(out)")
            XCTAssertFalse(out.isEmpty)
        }
    }

    func testKnownLiaison() {
        let g = KOG2P()
        // 좋다: 좋 + 다 → ㅎ+ㄷ tensifies/aspirates → 조타
        XCTAssertEqual(g.phonemize("좋다", toSyllable: true), "조타")
        // 학교: ㄱ+ㄱ → ㄲ → 학꾜
        XCTAssertEqual(g.phonemize("학교", toSyllable: true), "학꾜")
        // 맑다: ㄺ+ㄷ → ㄱ+ㄸ → 막따
        XCTAssertEqual(g.phonemize("맑다", toSyllable: true), "막따")
        // 값이: ㅄ+ㅇ liaison (rule 14) → ㅂ+ㅆ → 갑씨
        XCTAssertEqual(g.phonemize("값이", toSyllable: true), "갑씨")
    }

    func testNumerals() {
        XCTAssertEqual(KONumerals.processNum("0", sino: true), "영")
        print("KO num 123: \(KONumerals.processNum("123", sino: true))")
        print("KO convertNum '3개': \(KONumerals.convertNum("3개"))")
    }
}
