import XCTest
@testable import MisakiJA

final class JAG2PTests: XCTestCase {

    func testTableLoaded() {
        XCTAssertEqual(JATables.m2p.count, 193)
        XCTAssertEqual(JATables.m2p["\u{30CF}"], "ha")   // ハ
        XCTAssertEqual(JATables.m2p["\u{30B7}"], "\u{0255}i") // シ → ɕi
        XCTAssertEqual(JATables.m2p["\u{30F3}"], "\u{0274}")  // ン → ɴ
        XCTAssertEqual(JATables.m2p["\u{30C3}"], "\u{0294}")  // ッ → ʔ
        XCTAssertEqual(JATables.m2p["\u{30FC}"], "\u{02D0}")  // ー → ː
    }

    func testPron2Moras() {
        // キャク → キャ + ク (two-kana mora merge)
        XCTAssertEqual(JAG2P.pron2moras("\u{30AD}\u{30E3}\u{30AF}"), ["\u{30AD}\u{30E3}", "\u{30AF}"])
        // ニッポン → ニ ッ ポ ン (single-char special moras)
        XCTAssertEqual(JAG2P.pron2moras("\u{30CB}\u{30C3}\u{30DD}\u{30F3}"),
                       ["\u{30CB}", "\u{30C3}", "\u{30DD}", "\u{30F3}"])
    }

    func testPron2MorasSkipsUnknown() {
        // 'X' is not in M2P → skipped
        XCTAssertEqual(JAG2P.pron2moras("\u{30CF}X\u{30B7}"), ["\u{30CF}", "\u{30B7}"])
    }

    /// Single word 橋 / ハシ, accent nucleus on mora 2 (atamadaka-ish acc=2).
    /// Hand-derived: moras [ハ,シ]; accents [0,3]; phonemes "haɕi"; pitch "__^^".
    func testSingleWordAccent() {
        let engine = MockJAEngine([
            NJDWord(string: "\u{6A4B}", pron: "\u{30CF}\u{30B7}", pos: "\u{540D}\u{8A5E}",
                    acc: 2, moraSize: 2, chainFlag: 0)
        ])
        let (out, tokens) = JAG2P(engine: engine).phonemize("\u{6A4B}")
        XCTAssertEqual(out, "ha\u{0255}i__^^")          // haɕi + __^^
        XCTAssertEqual(tokens.count, 1)
        XCTAssertEqual(tokens[0].phonemes, "ha\u{0255}i")
        XCTAssertEqual(tokens[0].pitch, "__^^")
    }

    /// Heiban (acc=0) accent pattern over 3 moras → accents [0,1,2] → pitch "_--" per-mora.
    func testHeibanPattern() {
        // サクラ: サ=sa, ク=ku, ラ=ra (all 2-char phonemes)
        let engine = MockJAEngine([
            NJDWord(string: "\u{685C}", pron: "\u{30B5}\u{30AF}\u{30E9}", pos: "\u{540D}\u{8A5E}",
                    acc: 0, moraSize: 3, chainFlag: 0)
        ])
        let (out, _) = JAG2P(engine: engine).phonemize("\u{685C}")
        // phonemes sakura; pitch: mora1 a0→__, mora2 a1→--, mora3 a2→--  => "__----"
        XCTAssertEqual(out, "sakura__----")
    }

    func testPunctuationStop() {
        let engine = MockJAEngine([
            NJDWord(string: "\u{30CF}", pron: "\u{30CF}", pos: "X", acc: 1, moraSize: 1, chainFlag: 0),
            NJDWord(string: "\u{3002}", pron: "", pos: "\u{8A18}\u{53F7}", acc: 0, moraSize: 0, chainFlag: 0) // 。→ .
        ])
        let (out, tokens) = JAG2P(engine: engine).phonemize("\u{30CF}\u{3002}")
        XCTAssertTrue(out.hasPrefix("ha"))
        XCTAssertTrue(out.contains("."))      // mapped 。→ .
        XCTAssertEqual(tokens.last?.text, ".")
    }
}

final class OpenJTalkIntegrationTests: XCTestCase {
    func testRealFrontend() throws {
        let g2p = try JAG2P.openJTalk()
        let cases = ["\u{3053}\u{3093}\u{306B}\u{3061}\u{306F}",       // こんにちは
                     "\u{65E5}\u{672C}\u{8A9E}",                         // 日本語
                     "\u{6771}\u{4EAC}\u{306B}\u{884C}\u{304D}\u{307E}\u{3059}\u{3002}"] // 東京に行きます。
        for t in cases {
            let (out, tokens) = g2p.phonemize(t)
            print("JA: \(t) -> \(out)  [\(tokens.count) tokens]")
            XCTAssertFalse(out.isEmpty)
            XCTAssertFalse(tokens.isEmpty)
        }
    }
}
