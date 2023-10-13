# Blockchain Commons QRCodeGenerator

### by Wolf McNally

QRCodeGenerator is a pure Swift translation of the [Project Nayuki QR code generator library](https://www.nayuki.io/page/qr-code-generator-library). Unlike Apple's built-in APIs for QR code generation, this package allows more sophisticated and tuneable encoding techniques that produce more compact QR codes in certain circumstances, including the ability to automatically optimize segmenting for greatest compactness. See the unit tests for examples.

See the [QRCodeGeneratorDemo](https://github.com/BlockchainCommons/QRCodeGeneratorDemo) repo for an iOS app that demonstrates this library.

## Why Another QR Code Generator?

The QR code standard provides for QR codes to be composed of a heterogenous sequence of "segments," each of which is optimized for encoding different sorts of data, and each requiring a different number of bits per character to encode. Therefore, choosing which segment type (or series of segment types) to use for efficient encoding is important.

| Segment Type | Bits Per Character | Character Set |
| :---  | :---  | :--- |
| `bytes` | 8 | `0x00` - `0xff` |
| `numeric` | 3.33 | `0123456789` |
| `alphanumeric ` | 5.5 | `0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ $%*+-./:` |
| `kanji` | 13 | [Shift JIS](https://en.wikipedia.org/wiki/Shift_JIS) |

Many QR code generators, including the one built into iOS and macOS, take an undifferentiated block of byte data as input and analyze it to determine which single segment type can most efficiently encode it. For instance, if the block contains only the ASCII Arabic numerals, the `numeric` segment type is selected. This results in the encoding only taking 3.33 bits per character. Similarly, if every character in the input block is in the limited character set provided by the `alphanumeric` encoding node, the encoding takes only 5.5 bits per character.

The [Blockchain Commons UR standard](https://github.com/BlockchainCommons/Research/blob/master/papers/bcr-2020-005-ur.md) is designed to be compatible with the `alphanumeric` segment encoding node: URs are case-insensitive, and when a UR is transformed to upper case, it always is encodable in the `alphanumeric` mode. This results in an efficient encoding and therefore a less-dense QR code.

However, not all formats are this straightforward. For example the data for the [SMART Health Card (SHC)](https://smarthealth.cards/) format is a URI that starts `shc:/` followed by often over a thousand numeric digits. The first five characters require the `bytes` encoding mode, while the following digits would be most efficiently encoded using the `numeric` mode. But if only one segment type can be selected, then it must be the `bytes` mode. For the SHC format, this results in a much denser QR code that requires more screen resolution to display and higher quality cameras to read. The solution is to encode the data as two segments: the first encoding the header using the `bytes` mode, and the second with the body using the `numeric` mode.

It important to understand that no matter how many segments of any kind are used to create a QR code, all QR code readers are capable of reading them. So which segments to use is strictly a matter for the encoder to decide: the decoder always sees a scanned QR code as a string of UTF-8 bytes.

So for certain data types, the QR code generator built into iOS and macOS will have less than efficient results. This QRCodeGenerator package allows you to automatically pick a segment type as the built-in generator does, or specify a sequence of segments, giving you control of encoding efficiency over all the segments.

If you know the most efficient encoding for a data format in advance, you can manually specify a series of segments. But QRCodeGenerator also includes "optimal encoding" functions that search for and discover not a *single* segment type, but a *sequence* of most-efficient segment types. The use of this optimal encoding is optional because it does take a bit more processing power to search the space of possible segment encoding types to arrive at the optimal one.

The ability to manually specify a sequence of segment types, or to have the package pick an optimal one automatically are the major advantages that QRCodeGenerator has over the built-in generator.

As an example: the following Chinese string includes a variety of types of characters:

```
維基百科（Wikipedia，聆聽i/ˌwɪkᵻˈpiːdi.ə/）是一個自由內容、公開編輯且多語言的網路百科全書協作計畫
```

If `Segment.makeBytes(text:)` is called with the above string, it returns the following single `Segment` that requires 1120 bits of space to encode:

```
Segment(mode: byte, characterCount: 140, data: <1120 bits>)
```

However, if `Segment.makeSegmentsOptimally(text:)` is called, it returns the following sequence of `Segment`s:

```
Segment(mode: kanji, characterCount: 5, data: <65 bits>)
Segment(mode: byte, characterCount: 9, data: <72 bits>)
Segment(mode: kanji, characterCount: 3, data: <39 bits>)
Segment(mode: byte, characterCount: 23, data: <184 bits>)
Segment(mode: kanji, characterCount: 6, data: <78 bits>)
Segment(mode: byte, characterCount: 3, data: <24 bits>)
Segment(mode: kanji, characterCount: 21, data: <273 bits>)
```

This totals to 735 bits, a 48% savings.

## Status - Release

QRCodeGenerator is a translation of [Nayuki's library](https://www.nayuki.io/page/qr-code-generator-library). Its unit tests verify that it produces the exact same QR codes as those produced in the original source demo app. The maintainers believe this release to be stable and useful.

## Prerequisites

This package has no dependencies. When compiled for iOS or macOS, the `QRCode` type has a `makeImage` function that produces a `UIImage` or `NSImage` that allows the specification of border size, module size, and colors.

## Installation Instructions

Add this package to your project as a normal Swift package.

## Usage Instructions

See the unit tests for extensive examples of use. A simple example:

```swift
let qr = try QRCode.encode(text: "Hello, world!", correctionLevel: .low)
print(qr.emojiString)

⬛️⬛️⬛️⬛️⬛️⬛️⬛️⬜️⬜️⬜️⬜️⬜️⬛️⬜️⬛️⬛️⬛️⬛️⬛️⬛️⬛️
⬛️⬜️⬜️⬜️⬜️⬜️⬛️⬜️⬜️⬛️⬜️⬛️⬜️⬜️⬛️⬜️⬜️⬜️⬜️⬜️⬛️
⬛️⬜️⬛️⬛️⬛️⬜️⬛️⬜️⬛️⬜️⬛️⬛️⬛️⬜️⬛️⬜️⬛️⬛️⬛️⬜️⬛️
⬛️⬜️⬛️⬛️⬛️⬜️⬛️⬜️⬛️⬜️⬜️⬜️⬜️⬜️⬛️⬜️⬛️⬛️⬛️⬜️⬛️
⬛️⬜️⬛️⬛️⬛️⬜️⬛️⬜️⬛️⬛️⬜️⬜️⬛️⬜️⬛️⬜️⬛️⬛️⬛️⬜️⬛️
⬛️⬜️⬜️⬜️⬜️⬜️⬛️⬜️⬛️⬛️⬛️⬛️⬜️⬜️⬛️⬜️⬜️⬜️⬜️⬜️⬛️
⬛️⬛️⬛️⬛️⬛️⬛️⬛️⬜️⬛️⬜️⬛️⬜️⬛️⬜️⬛️⬛️⬛️⬛️⬛️⬛️⬛️
⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬛️⬜️⬛️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️
⬛️⬜️⬛️⬛️⬛️⬛️⬛️⬜️⬜️⬛️⬛️⬛️⬜️⬜️⬛️⬛️⬛️⬛️⬛️⬜️⬜️
⬜️⬜️⬜️⬛️⬛️⬜️⬜️⬛️⬛️⬜️⬜️⬜️⬛️⬛️⬜️⬜️⬛️⬛️⬛️⬜️⬛️
⬜️⬜️⬜️⬛️⬜️⬜️⬛️⬜️⬛️⬛️⬛️⬜️⬛️⬛️⬛️⬜️⬜️⬛️⬛️⬛️⬜️
⬜️⬛️⬛️⬜️⬜️⬛️⬜️⬛️⬜️⬜️⬛️⬛️⬛️⬛️⬜️⬛️⬜️⬛️⬛️⬜️⬜️
⬛️⬛️⬜️⬛️⬛️⬛️⬛️⬜️⬛️⬜️⬜️⬜️⬛️⬜️⬛️⬛️⬜️⬜️⬜️⬜️⬛️
⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬜️⬛️⬜️⬜️⬜️⬜️⬛️⬛️⬛️⬛️⬛️⬜️⬜️⬜️
⬛️⬛️⬛️⬛️⬛️⬛️⬛️⬜️⬜️⬛️⬛️⬜️⬛️⬛️⬛️⬛️⬜️⬜️⬛️⬛️⬜️
⬛️⬜️⬜️⬜️⬜️⬜️⬛️⬜️⬛️⬜️⬛️⬜️⬛️⬛️⬜️⬛️⬜️⬛️⬛️⬛️⬜️
⬛️⬜️⬛️⬛️⬛️⬜️⬛️⬜️⬛️⬛️⬜️⬛️⬛️⬛️⬛️⬜️⬛️⬜️⬜️⬛️⬛️
⬛️⬜️⬛️⬛️⬛️⬜️⬛️⬜️⬛️⬜️⬛️⬜️⬜️⬜️⬜️⬛️⬛️⬛️⬜️⬜️⬜️
⬛️⬜️⬛️⬛️⬛️⬜️⬛️⬜️⬛️⬛️⬛️⬛️⬛️⬜️⬛️⬛️⬜️⬜️⬛️⬜️⬜️
⬛️⬜️⬜️⬜️⬜️⬜️⬛️⬜️⬜️⬜️⬛️⬜️⬛️⬛️⬜️⬜️⬛️⬛️⬛️⬜️⬜️
⬛️⬛️⬛️⬛️⬛️⬛️⬛️⬜️⬛️⬛️⬜️⬛️⬜️⬜️⬛️⬜️⬛️⬜️⬜️⬛️⬜️
```

## Origin, Authors, Copyright & Licenses

Unless otherwise noted (either in this [/README.md](./README.md) or in the file's header comments) the contents of this repository are Copyright © 2021 by Blockchain Commons, LLC, and are [licensed](./LICENSE) under the [spdx:BSD-2-Clause Plus Patent License](https://spdx.org/licenses/BSD-2-Clause-Patent.html).

### Derived from ...

This  QRCodeGenerator project is either derived from or was inspired by:

* The [Project Nayuki QR Code generator library](https://www.nayuki.io/page/qr-code-generator-library)

While this project does not include any actual source code from the Nayuki's library, it is closely based on that library's C++ implementation, which is released under the MIT license.

## Financial Support

QRCodeGenerator is a project of [Blockchain Commons](https://www.blockchaincommons.com/). We are proudly a "not-for-profit" social benefit corporation committed to open source & open development. Our work is funded entirely by donations and collaborative partnerships with people like you. Every contribution will be spent on building open tools, technologies, and techniques that sustain and advance blockchain and internet security infrastructure and promote an open web.

To financially support further development of QRCodeGenerator and other projects, please consider becoming a Patron of Blockchain Commons through ongoing monthly patronage as a [GitHub Sponsor](https://github.com/sponsors/BlockchainCommons). You can also support Blockchain Commons with bitcoins at our [BTCPay Server](https://btcpay.blockchaincommons.com/).

## Contributing

We encourage public contributions through issues and pull requests! Please review [CONTRIBUTING.md](./CONTRIBUTING.md) for details on our development process. All contributions to this repository require a GPG signed [Contributor License Agreement](./CLA.md).

### Discussions

The best place to talk about Blockchain Commons and its projects is in our GitHub Discussions areas.

[**Gordian Developer Community**](https://github.com/BlockchainCommons/Gordian-Developer-Community/discussions). For standards and open-source developers who want to talk about interoperable wallet specifications, please use the Discussions area of the [Gordian Developer Community repo](https://github.com/BlockchainCommons/Gordian-Developer-Community/discussions). This is where you talk about Gordian specifications such as [Gordian Envelope](https://github.com/BlockchainCommons/Gordian/tree/master/Envelope#articles), [bc-shamir](https://github.com/BlockchainCommons/bc-shamir), [Sharded Secret Key Reconstruction](https://github.com/BlockchainCommons/bc-sskr), and [bc-ur](https://github.com/BlockchainCommons/bc-ur) as well as the larger [Gordian Architecture](https://github.com/BlockchainCommons/Gordian/blob/master/Docs/Overview-Architecture.md), its [Principles](https://github.com/BlockchainCommons/Gordian#gordian-principles) of independence, privacy, resilience, and openness, and its macro-architectural ideas such as functional partition (including airgapping, the original name of this community).

[**Blockchain Commons Discussions**](https://github.com/BlockchainCommons/Community/discussions). For developers, interns, and patrons of Blockchain Commons, please use the discussions area of the [Community repo](https://github.com/BlockchainCommons/Community) to talk about general Blockchain Commons issues, the intern program, or topics other than those covered by the [Gordian Developer Community](https://github.com/BlockchainCommons/Gordian-Developer-Community/discussions) or the 
[Gordian User Community](https://github.com/BlockchainCommons/Gordian/discussions).
### Other Questions & Problems

As an open-source, open-development community, Blockchain Commons does not have the resources to provide direct support of our projects. Please consider the discussions area as a locale where you might get answers to questions. Alternatively, please use this repository's [issues](./issues) feature. Unfortunately, we can not make any promises on response time.

If your company requires support to use our projects, please feel free to contact us directly about options. We may be able to offer you a contract for support from one of our contributors, or we might be able to point you to another entity who can offer the contractual support that you need.

### Credits

The following people directly contributed to this repository. You can add your name here by getting involved. The first step is learning how to contribute from our [CONTRIBUTING.md](./CONTRIBUTING.md) documentation.

| Name              | Role                | Github                                            | Email                                 | GPG Fingerprint                                    |
| ----------------- | ------------------- | ------------------------------------------------- | ------------------------------------- | -------------------------------------------------- |
| Wolf McNally | Project Lead | [@WolfMcNally](https://github.com/WolfMcNally) | \<Wolf@WolfMcNally.com\> | 9436 52EE 3844 1760 C3DC  3536 4B6C 2FCF 8947 80AE |
| Christopher Allen | Principal Architect | [@ChristopherA](https://github.com/ChristopherA) | \<ChristopherA@LifeWithAlacrity.com\> | FDFE 14A5 4ECB 30FC 5D22  74EF F8D3 6C91 3574 05ED |

## Responsible Disclosure

We want to keep all of our software safe for everyone. If you have discovered a security vulnerability, we appreciate your help in disclosing it to us in a responsible manner. We are unfortunately not able to offer bug bounties at this time.

We do ask that you offer us good faith and use best efforts not to leak information or harm any user, their data, or our developer community. Please give us a reasonable amount of time to fix the issue before you publish it. Do not defraud our users or us in the process of discovery. We promise not to bring legal action against researchers who point out a problem provided they do their best to follow the these guidelines.

### Reporting a Vulnerability

Please report suspected security vulnerabilities in private via email to ChristopherA@BlockchainCommons.com (do not use this email for support). Please do NOT create publicly viewable issues for suspected security vulnerabilities.

The following keys may be used to communicate sensitive information to developers:

| Name              | Fingerprint                                        |
| ----------------- | -------------------------------------------------- |
| Christopher Allen | FDFE 14A5 4ECB 30FC 5D22  74EF F8D3 6C91 3574 05ED |

You can import a key by running the following command with that individual’s fingerprint: `gpg --recv-keys "<fingerprint>"` Ensure that you put quotes around fingerprints that contain spaces.
