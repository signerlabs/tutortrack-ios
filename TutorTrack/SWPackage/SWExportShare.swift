//
//  SWExportShare.swift
//  TutorTrack — local implementation (substitutes the Pro Recipe `export-share`
//  when the Pro key is not unlocked).
//
//  Minimal PDF export: SwiftUI View -> ImageRenderer -> PDFKit -> temp file ->
//  return URL for ShareLink.
//  - Single page (A4 595 x 842 pt)
//  - Auto-injects PDF metadata (Title / Author / Creator)
//  - File name embeds the student's name + week so files do not collide
//  - Zero dependencies (pure SwiftUI ImageRenderer + PDFKit)
//

import SwiftUI
import PDFKit
import UniformTypeIdentifiers

@MainActor
enum SWExportShare {

    // MARK: - A4 size (points)

    /// A4 page size (at 72 dpi: 1 inch = 72 pt; A4 = 8.27 x 11.69 inch ≈ 595.2 x 841.8 pt)
    static let a4Size = CGSize(width: 595, height: 842)

    // MARK: - Errors

    enum ExportError: Error, LocalizedError {
        case renderFailed
        case writeFailed(Error)

        var errorDescription: String? {
            switch self {
            case .renderFailed:
                return "PDF rendering failed"
            case .writeFailed(let error):
                return "PDF write failed: \(error.localizedDescription)"
            }
        }
    }

    // MARK: - Entry: SwiftUI View -> temp PDF file URL

    /// Render any SwiftUI View as a single-page PDF, write it to a temp file,
    /// and return its URL.
    /// - Parameters:
    ///   - view: the SwiftUI View to render (wrap with frame(width: 595, height: 842))
    ///   - fileName: file name (no extension; the function appends .pdf)
    ///   - title: PDF metadata Title
    ///   - author: PDF metadata Author
    /// - Returns: a temp-directory PDF file URL ready for ShareLink
    static func renderSinglePagePDF<V: View>(
        view: V,
        fileName: String,
        title: String = "TutorTrack Report",
        author: String = "TutorTrack"
    ) throws -> URL {
        // 1. Use ImageRenderer to get a renderer that can drive a CGContext
        let renderer = ImageRenderer(content:
            view
                .frame(width: a4Size.width, height: a4Size.height)
                .background(Color.white)
        )
        renderer.proposedSize = .init(a4Size)

        // 2. Compute the output path
        let safeName = sanitizeFileName(fileName)
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(safeName).pdf")

        // 3. Remove any stale file
        try? FileManager.default.removeItem(at: url)

        // 4. PDF metadata
        let pdfInfo: [CFString: Any] = [
            kCGPDFContextTitle: title,
            kCGPDFContextAuthor: author,
            kCGPDFContextCreator: "TutorTrack"
        ]

        // 5. Write the PDF
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

    // MARK: - Utility: safe file name

    private static func sanitizeFileName(_ raw: String) -> String {
        let invalid = CharacterSet(charactersIn: "/\\?%*|\"<>:")
        return raw.components(separatedBy: invalid).joined(separator: "_")
    }
}

// MARK: - Transferable URL for ShareLink

/// SwiftUI's ShareLink accepts a URL directly — no Transferable wrapper needed;
/// `ShareLink(item: url)` is enough. This block exists only to document usage:
///
/// ```swift
/// if let pdfURL {
///     ShareLink(item: pdfURL, preview: SharePreview("WeeklyReport.pdf"))
/// }
/// ```
