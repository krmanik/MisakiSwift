// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "MisakiSwift",
  platforms: [
    .iOS(.v18), .macOS(.v15)
  ],
  products: [
    // English-only G2P (lightweight - no Chinese dictionaries or C++ deps)
    .library(
      name: "MisakiSwift",
      targets: ["MisakiSwift"]
    ),
    // Chinese G2P - includes English support via MisakiSwift dependency
    .library(
      name: "MisakiZH",
      targets: ["MisakiZH"]
    ),
    // CppJieba C++ wrapper (for external packages needing jieba tokenization)
    .library(
      name: "CppJieba",
      targets: ["CppJieba"]
    ),
    // Korean G2P - pure Swift (v0: no native deps)
    .library(
      name: "MisakiKO",
      targets: ["MisakiKO"]
    ),
    // Japanese G2P - pure Swift transformation layer (engine via JAEngine protocol)
    .library(
      name: "MisakiJA",
      targets: ["MisakiJA"]
    ),
  ],
  dependencies: [
    .package(url: "https://github.com/ml-explore/mlx-swift", exact: "0.30.2"),
    // .package(url: "https://github.com/mlalma/MLXUtilsLibrary.git", exact: "0.0.6")
    .package(path: "../MLXUtilsLibrary")
  ],
  targets: [
    // MARK: - English G2P
    .target(
      name: "MisakiSwift",
      dependencies: [
        .product(name: "MLX", package: "mlx-swift"),
        .product(name: "MLXNN", package: "mlx-swift"),
        .product(name: "MLXUtilsLibrary", package: "MLXUtilsLibrary")
      ],
      resources: [
        .process("Resources")
      ],
    ),

    // MARK: - Chinese G2P (includes English via MisakiSwift)
    // C++ wrapper for cppjieba (Chinese word segmentation)
    .target(
      name: "CppJieba",
      dependencies: [],
      path: "Sources/CppJieba",
      exclude: [
        "cppjieba/.git",
        "cppjieba/.github",
        "cppjieba/.gitignore",
        "cppjieba/.gitmodules",
        "cppjieba/CHANGELOG.md",
        "cppjieba/CMakeLists.txt",
        "cppjieba/LICENSE",
        "cppjieba/README.md",
        "cppjieba/test",
        "cppjieba/dict",
        "cppjieba/deps/limonp/.git",
        "cppjieba/deps/limonp/.github",
        "cppjieba/deps/limonp/.gitignore",
        "cppjieba/deps/limonp/.gitmodules",
        "cppjieba/deps/limonp/CHANGELOG.md",
        "cppjieba/deps/limonp/CMakeLists.txt",
        "cppjieba/deps/limonp/LICENSE",
        "cppjieba/deps/limonp/README.md",
        "cppjieba/deps/limonp/test",
      ],
      sources: [
        "jieba_bridge.cpp",
      ],
      publicHeadersPath: "include",
      cxxSettings: [
        .headerSearchPath("cppjieba/include"),
        .headerSearchPath("cppjieba/deps/limonp/include"),
        .define("LOGGER_LEVEL", to: "LL_WARN"),
      ]
    ),
    .target(
      name: "MisakiZH",
      dependencies: [
        "CppJieba",
        "MisakiSwift",
        .product(name: "MLXUtilsLibrary", package: "MLXUtilsLibrary")
      ],
      path: "Sources/MisakiZH",
      resources: [
        .copy("Resources/dict"),
      ]
    ),

    // MARK: - Korean G2P (pure Swift, v0)
    .target(
      name: "MisakiKO",
      dependencies: ["MisakiSwift"],
      path: "Sources/MisakiKO",
      resources: [
        .copy("Resources/table.csv"),
        .copy("Resources/idioms.txt"),
        .copy("Resources/rules.txt"),
      ]
    ),

    // MARK: - OpenJTalk frontend C bridge (Japanese morph + accent analysis)
    .target(
      name: "CppOpenJTalk",
      dependencies: [],
      path: "Sources/CppOpenJTalk",
      publicHeadersPath: "include",
      cxxSettings: [
        .headerSearchPath("openjtalk/mecab"),
        .headerSearchPath("openjtalk/njd"),
        .headerSearchPath("openjtalk/text2mecab"),
        .headerSearchPath("openjtalk/mecab2njd"),
        .headerSearchPath("openjtalk/njd_set_pronunciation"),
        .headerSearchPath("openjtalk/njd_set_digit"),
        .headerSearchPath("openjtalk/njd_set_accent_phrase"),
        .headerSearchPath("openjtalk/njd_set_accent_type"),
        .headerSearchPath("openjtalk/njd_set_unvoiced_vowel"),
        .headerSearchPath("openjtalk/njd_set_long_vowel"),
        .define("HAVE_CONFIG_H"),
        .define("DIC_VERSION", to: "102"),
        .define("MECAB_DEFAULT_RC", to: "\"dummy\""),
        .define("PACKAGE", to: "\"open_jtalk\""),
        .define("VERSION", to: "\"1.11\""),
        .define("CHARSET_UTF_8"),
        .define("MECAB_UTF8_USE_ONLY"),
      ]
    ),

    // MARK: - Japanese G2P (pure Swift core + OpenJTalk engine)
    .target(
      name: "MisakiJA",
      dependencies: ["CppOpenJTalk"],
      path: "Sources/MisakiJA",
      resources: [
        .copy("Resources/open_jtalk_dic"),
      ]
    ),

    // MARK: - Tests
    .testTarget(
      name: "MisakiSwiftTests",
      dependencies: ["MisakiSwift"]
    ),
    .testTarget(
      name: "MisakiKOTests",
      dependencies: ["MisakiKO"]
    ),
    .testTarget(
      name: "MisakiJATests",
      dependencies: ["MisakiJA"]
    ),
    .testTarget(
      name: "MisakiZHTests",
      dependencies: [
        "MisakiZH",
        .product(name: "MLXUtilsLibrary", package: "MLXUtilsLibrary")
      ]
    ),
  ],
  cxxLanguageStandard: .cxx17
)
