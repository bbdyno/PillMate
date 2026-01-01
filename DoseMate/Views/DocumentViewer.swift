//
//  DocumentViewer.swift
//  DoseMate
//
//  Created by bbdyno on 1/1/26.
//

import SwiftUI
import DMateDesignSystem
import DMateResource

/// 마크다운 문서 뷰어
struct DocumentViewer: View {
    @Environment(\.dismiss) private var dismiss
    let title: String
    let fileName: String

    @State private var content: AttributedString = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                Text(content)
                    .font(AppTypography.body)
                    .foregroundColor(AppColors.textPrimary)
                    .padding()
            }
            .background(AppColors.background)
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(DMateResourceStrings.Common.close) {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            loadMarkdown()
        }
    }

    private func loadMarkdown() {
        guard let url = Bundle.main.url(forResource: fileName, withExtension: "md"),
              let markdown = try? String(contentsOf: url) else {
            content = AttributedString("Failed to load document.")
            return
        }

        do {
            content = try AttributedString(markdown: markdown, options: AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace))
        } catch {
            content = AttributedString(markdown)
        }
    }
}
