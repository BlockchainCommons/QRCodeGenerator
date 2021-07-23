# Blockchain Commons QRCodeGenerator

### by Wolf McNally

QRCodeGenerator is a pure Swift translation of the [Project Nayuki QR code generator library](https://www.nayuki.io/page/qr-code-generator-library). Unlike Apple's built-in APIs for QR code generation, this package allows more sophisticated and tuneable encoding techniques that produce more compact QR codes in certain circumstances. See the unit tests for examples.

## Status - Late Alpha

QRCodeGenerator is a translation of the [Project Nayuki QR Code generator library](https://www.nayuki.io/page/qr-code-generator-library), and while the original source has been released and tested for years, this translation is new. Its unit tests verify that it produces the exact same QR codes as those produced in the original source demo app.

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

While this project does not include any actual source code from the [Project Nayuki QR Code generator library](https://www.nayuki.io/page/qr-code-generator-library), it is closely based on that library's C++ implementation, which is released under the MIT license.

## Financial Support

QRCodeGenerator is a project of [Blockchain Commons](https://www.blockchaincommons.com/). We are proudly a "not-for-profit" social benefit corporation committed to open source & open development. Our work is funded entirely by donations and collaborative partnerships with people like you. Every contribution will be spent on building open tools, technologies, and techniques that sustain and advance blockchain and internet security infrastructure and promote an open web.

To financially support further development of QRCodeGenerator and other projects, please consider becoming a Patron of Blockchain Commons through ongoing monthly patronage as a [GitHub Sponsor](https://github.com/sponsors/BlockchainCommons). You can also support Blockchain Commons with bitcoins at our [BTCPay Server](https://btcpay.blockchaincommons.com/).

## Contributing

We encourage public contributions through issues and pull requests! Please review [CONTRIBUTING.md](./CONTRIBUTING.md) for details on our development process. All contributions to this repository require a GPG signed [Contributor License Agreement](./CLA.md).

### Discussions

The best place to talk about Blockchain Commons and its projects is in our GitHub Discussions areas.

[**Gordian System Discussions**](https://github.com/BlockchainCommons/Gordian/discussions). For users and developers of the Gordian system, including the Gordian Server, Bitcoin Standup technology, QuickConnect, and the Gordian Wallet. If you want to talk about our linked full-node and wallet technology, suggest new additions to our Bitcoin Standup standards, or discuss the implementation our standalone wallet, the Discussions area of the [main Gordian repo](https://github.com/BlockchainCommons/Gordian) is the place.

[**Wallet Standard Discussions**](https://github.com/BlockchainCommons/AirgappedSigning/discussions). For standards and open-source developers who want to talk about wallet standards, please use the Discussions area of the [Airgapped Signing repo](https://github.com/BlockchainCommons/AirgappedSigning). This is where you can talk about projects like our [LetheKit](https://github.com/BlockchainCommons/bc-lethekit) and command line tools such as [seedtool](https://github.com/BlockchainCommons/bc-seedtool-cli), both of which are intended to testbed wallet technologies, plus the libraries that we've built to support your own deployment of wallet technology such as [bc-bip39](https://github.com/BlockchainCommons/bc-bip39), [bc-slip39](https://github.com/BlockchainCommons/bc-slip39), [bc-shamir](https://github.com/BlockchainCommons/bc-shamir), [Sharded Secret Key Reconstruction](https://github.com/BlockchainCommons/bc-sskr), [bc-ur](https://github.com/BlockchainCommons/bc-ur), and the [bc-crypto-base](https://github.com/BlockchainCommons/bc-crypto-base). If it's a wallet-focused technology or a more general discussion of wallet standards,discuss it here.

[**Blockchain Commons Discussions**](https://github.com/BlockchainCommons/Community/discussions). For developers, interns, and patrons of Blockchain Commons, please use the discussions area of the [Community repo](https://github.com/BlockchainCommons/Community) to talk about general Blockchain Commons issues, the intern program, or topics other than the [Gordian System](https://github.com/BlockchainCommons/Gordian/discussions) or the [wallet standards](https://github.com/BlockchainCommons/AirgappedSigning/discussions), each of which have their own discussion areas.

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
