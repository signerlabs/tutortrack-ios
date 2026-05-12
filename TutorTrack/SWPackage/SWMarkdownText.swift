//
//  SWMarkdownText.swift
//  TutorTrack — ShipSwift Recipe: component-markdown-text
//
//  Lightweight Markdown renderer. Supports headings / fenced code blocks /
//  lists / dividers / inline formatting (bold / italic / inline code). Used
//  here to render the AI weekly report paragraph produced by
//  WeeklyReportEngine so it reads like LLM output.
//

import SwiftUI

// MARK: - SWMarkdownText

public struct SWMarkdownText: View {
    public let text: String
    public var codeBackground: Color
    public var codeBorderColor: Color
    public var codeCornerRadius: CGFloat
    public var blockSpacing: CGFloat

    public init(
        _ text: String,
        codeBackground: Color = .gray.opacity(0.12),
        codeBorderColor: Color = .secondary,
        codeCornerRadius: CGFloat = 8,
        blockSpacing: CGFloat = 6
    ) {
        self.text = text
        self.codeBackground = codeBackground
        self.codeBorderColor = codeBorderColor
        self.codeCornerRadius = codeCornerRadius
        self.blockSpacing = blockSpacing
    }

    public var body: some View {
        if text.isEmpty {
            EmptyView()
        } else {
            VStack(alignment: .leading, spacing: blockSpacing) {
                ForEach(Array(parseBlocks().enumerated()), id: \.offset) { _, block in
                    blockView(for: block)
                }
            }
        }
    }

    @ViewBuilder
    private func blockView(for block: SWMarkdownBlock) -> some View {
        switch block {
        case .heading(let level, let content):
            headingView(level: level, content: content)

        case .codeBlock(let language, let code):
            codeBlockView(language: language, code: code)

        case .divider:
            Divider()
                .padding(.vertical, 4)

        case .listItem(let content):
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text("\u{2022}")
                    .foregroundStyle(.secondary)
                inlineMarkdownText(content)
            }
            .padding(.leading, 12)

        case .paragraph(let content):
            inlineMarkdownText(content)
        }
    }

    private func headingView(level: Int, content: String) -> some View {
        let font: Font = switch level {
        case 1: .title.bold()
        case 2: .title2.bold()
        case 3: .title3.bold()
        default: .headline.bold()
        }
        return inlineMarkdownText(content)
            .font(font)
            .padding(.top, level <= 2 ? 6 : 2)
    }

    private func codeBlockView(language: String, code: String) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            if !language.isEmpty {
                Text(language)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 10)
                    .padding(.top, 6)
                    .padding(.bottom, 2)
            }
            ScrollView(.horizontal, showsIndicators: false) {
                Text(code)
                    .font(.system(.body, design: .monospaced))
                    .textSelection(.enabled)
                    .padding(10)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(codeBackground.opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: codeCornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: codeCornerRadius)
                .strokeBorder(codeBorderColor.opacity(0.5), lineWidth: 0.5)
        )
    }

    private func inlineMarkdownText(_ text: String) -> Text {
        if let attributed = try? AttributedString(
            markdown: text,
            options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)
        ) {
            return Text(attributed)
        }
        return Text(text)
    }

    private func parseBlocks() -> [SWMarkdownBlock] {
        var blocks: [SWMarkdownBlock] = []
        let lines = text.components(separatedBy: "\n")
        var i = 0

        while i < lines.count {
            let line = lines[i]
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            if trimmed.hasPrefix("```") {
                let language = String(trimmed.dropFirst(3)).trimmingCharacters(in: .whitespaces)
                var codeLines: [String] = []
                i += 1
                while i < lines.count {
                    let codeLine = lines[i]
                    if codeLine.trimmingCharacters(in: .whitespaces).hasPrefix("```") {
                        i += 1
                        break
                    }
                    codeLines.append(codeLine)
                    i += 1
                }
                blocks.append(.codeBlock(language: language, code: codeLines.joined(separator: "\n")))
                continue
            }

            if isDivider(trimmed) {
                blocks.append(.divider)
                i += 1
                continue
            }

            if let (level, content) = parseHeading(trimmed) {
                blocks.append(.heading(level: level, content: content))
                i += 1
                continue
            }

            if let content = parseUnorderedListItem(trimmed) {
                blocks.append(.listItem(content: content))
                i += 1
                continue
            }

            if let content = parseOrderedListItem(trimmed) {
                blocks.append(.listItem(content: content))
                i += 1
                continue
            }

            if trimmed.isEmpty {
                i += 1
                continue
            }

            var paragraphLines: [String] = [line]
            i += 1
            while i < lines.count {
                let nextLine = lines[i]
                let nextTrimmed = nextLine.trimmingCharacters(in: .whitespaces)
                if nextTrimmed.isEmpty ||
                    parseHeading(nextTrimmed) != nil ||
                    nextTrimmed.hasPrefix("```") ||
                    parseUnorderedListItem(nextTrimmed) != nil ||
                    parseOrderedListItem(nextTrimmed) != nil ||
                    isDivider(nextTrimmed) {
                    break
                }
                paragraphLines.append(nextLine)
                i += 1
            }
            blocks.append(.paragraph(content: paragraphLines.joined(separator: "\n")))
        }

        return blocks
    }

    private func parseHeading(_ line: String) -> (Int, String)? {
        var level = 0
        var idx = line.startIndex
        while idx < line.endIndex && line[idx] == "#" && level < 4 {
            level += 1
            idx = line.index(after: idx)
        }
        guard level > 0, idx < line.endIndex, line[idx] == " " else { return nil }
        let content = String(line[line.index(after: idx)...]).trimmingCharacters(in: .whitespaces)
        guard !content.isEmpty else { return nil }
        return (level, content)
    }

    private func parseUnorderedListItem(_ line: String) -> String? {
        guard let first = line.first, "-*+".contains(first),
              line.count >= 2,
              line[line.index(after: line.startIndex)] == " " else { return nil }
        let content = String(line.dropFirst(2)).trimmingCharacters(in: .whitespaces)
        return content.isEmpty ? nil : content
    }

    private func parseOrderedListItem(_ line: String) -> String? {
        guard let dotIndex = line.firstIndex(of: ".") else { return nil }
        let prefix = line[line.startIndex..<dotIndex]
        guard !prefix.isEmpty, prefix.allSatisfy(\.isNumber) else { return nil }
        let afterDot = line.index(after: dotIndex)
        guard afterDot < line.endIndex, line[afterDot] == " " else { return nil }
        let content = String(line[line.index(after: afterDot)...]).trimmingCharacters(in: .whitespaces)
        return content.isEmpty ? nil : content
    }

    private func isDivider(_ line: String) -> Bool {
        guard line.count >= 3 else { return false }
        return line.allSatisfy({ $0 == "-" }) ||
               line.allSatisfy({ $0 == "*" }) ||
               line.allSatisfy({ $0 == "_" })
    }
}

private enum SWMarkdownBlock {
    case heading(level: Int, content: String)
    case codeBlock(language: String, code: String)
    case divider
    case listItem(content: String)
    case paragraph(content: String)
}
