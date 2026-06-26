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

extension KOG2PTests {
    func testEnglishCmudict() {
        // g2pk docstring: convert_eng("그 사람 좀 old school이야") -> "그 사람 좀 올드 스쿨이야"
        let out = KOEnglish.convertEng("그 사람 좀 old school이야")
        print("KO eng: \(out)")
        XCTAssertEqual(out, "그 사람 좀 올드 스쿨이야")
    }
    func testEnglishAcronym() {
        // uppercase / OOV → letter spelling
        XCTAssertEqual(KOEnglish.convertEng("MP3"), "엠피3")
    }
}

extension KOG2PTests {
    func testMecabAvailable() {
        guard let m = MecabKo.shared else { XCTFail("mecab-ko-dic not loaded"); return }
        let pos = m.pos("나의 친구가")
        print("KO pos 나의친구가: \(pos)")
        XCTAssertFalse(pos.isEmpty)
    }
    func testFullPipelineWithDict() {
        let g = KOG2P()
        // g2pk docstring: "나의 친구가 mp3 file 3개를 다운받고 있다"
        //              -> "나의 친구가 엠피쓰리 파일 세개를 다운받꼬 읻따"
        let out = g.phonemize("나의 친구가 mp3 file 3개를 다운받고 있다", toSyllable: true)
        print("KO full: \(out)")
        XCTAssertEqual(out, "나의 친구가 엠피쓰리 파일 세개를 다운받꼬 읻따")
    }
}

extension KOG2PTests {
    func testSpecialRules() {
        let g = KOG2P()
        // modifying_rieul (rule 27): 할걸 → 할껄
        XCTAssertEqual(g.phonemize("할걸", toSyllable: true), "할껄")
        // balb (rule 10.1): 밟다 → 밥따
        XCTAssertEqual(g.phonemize("밟다", toSyllable: true), "밥따")
    }
}
