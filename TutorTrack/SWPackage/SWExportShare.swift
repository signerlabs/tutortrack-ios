//
//  SWExportShare.swift
//  TutorTrack — 本地实现（替代 Pro Recipe: export-share，Pro Key 未解锁）
//
//  极简 PDF 导出：SwiftUI View → ImageRenderer → PDFKit → 写入临时文件 → 返回 URL 喂给 ShareLink。
//  - 单页（A4 595 × 842 pt）
//  - 自动注入 PDF metadata（Title / Author / Creator）
//  - 文件命名带学员名 + 周次，避免覆盖
//  - 零依赖（纯 SwiftUI ImageRenderer + PDFKit）
//

import SwiftUI
import PDFKit
import UniformTypeIdentifiers

@MainActor
enum SWExportShare {

    // MARK: - A4 尺寸（points）

    /// A4 纸尺寸（72 dpi 下 1 inch = 72 pt，A4 = 8.27 × 11.69 inch ≈ 595.2 × 841.8 pt）
    static let a4Size = CGSize(width: 595, height: 842)

    // MARK: - 错误

    enum ExportError: Error, LocalizedError {
        case renderFailed
        case writeFailed(Error)

        var errorDescription: String? {
            switch self {
            case .renderFailed:
                return "PDF 渲染失败"
            case .writeFailed(let error):
                return "PDF 写入失败：\(error.localizedDescription)"
            }
        }
    }

    // MARK: - 入口：SwiftUI View → 临时 PDF 文件 URL

    /// 将任意 SwiftUI View 渲染成单页 PDF，写入临时目录并返回 URL。
    /// - Parameters:
    ///   - view: 要渲染的 SwiftUI View（建议外层包 frame(width: 595, height: 842)）
    ///   - fileName: 文件名（无后缀，函数自动加 .pdf）
    ///   - title: PDF metadata Title
    ///   - author: PDF metadata Author
    /// - Returns: 临时目录下的 PDF 文件 URL，供 ShareLink 使用
    static func renderSinglePagePDF<V: View>(
        view: V,
        fileName: String,
        title: String = "TutorTrack Report",
        author: String = "TutorTrack"
    ) throws -> URL {
        // 1. 用 ImageRenderer 拿到一个能写 CGContext 的渲染器
        let renderer = ImageRenderer(content:
            view
                .frame(width: a4Size.width, height: a4Size.height)
                .background(Color.white)
        )
        renderer.proposedSize = .init(a4Size)

        // 2. 计算输出路径
        let safeName = sanitizeFileName(fileName)
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(safeName).pdf")

        // 3. 删旧文件
        try? FileManager.default.removeItem(at: url)

        // 4. PDF metadata
        let pdfInfo: [CFString: Any] = [
            kCGPDFContextTitle: title,
            kCGPDFContextAuthor: author,
            kCGPDFContextCreator: "TutorTrack"
        ]

        // 5. 写入
        var success = false
        renderer.render { _, renderContext in
            var mediaBox = CGRect(origin: .zero, size: a4Size)
            guard let pdfContext = CGContext(
                url as CFURL,
                mediaBox: &mediaBox,
                pdfInfo as CFDictionary
            ) else {
                return
            }
            pdfContext.beginPDFPage(nil)
            renderContext(pdfContext)
            pdfContext.endPDFPage()
            pdfContext.closePDF()
            success = true
        }

        guard success else {
            throw ExportError.renderFailed
        }

        return url
    }

    // MARK: - 工具：安全文件名

    private static func sanitizeFileName(_ raw: String) -> String {
        let invalid = CharacterSet(charactersIn: "/\\?%*|\"<>:")
        return raw.components(separatedBy: invalid).joined(separator: "_")
    }
}

// MARK: - 给 ShareLink 用的 Transferable URL

/// SwiftUI ShareLink 直接接受 URL，无需再封装 Transferable —— ShareLink(item: url) 即可。
/// 此扩展只是为了文档化使用方式：
///
/// ```swift
/// if let pdfURL {
///     ShareLink(item: pdfURL, preview: SharePreview("家长周报.pdf"))
/// }
/// ```
