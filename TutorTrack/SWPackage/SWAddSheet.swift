//
//  SWAddSheet.swift
//  TutorTrack — ShipSwift Recipe: component-add-sheet
//
//  Bottom sheet（.medium detent），含多行 TextField + Cancel/Continue 按钮。
//

import SwiftUI

struct SWAddSheet: View {
    @Binding var isPresented: Bool
    @State private var inputText = ""

    var title: LocalizedStringKey = "Your Generation Purpose"
    var placeHolderText: LocalizedStringKey = "Enter your purpose/wish/favorite things for this generation (optional)..."
    var minLines: Int = 5
    var onConfirm: ((String) -> Void)?

    var body: some View {
        VStack {
            Text(title)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .padding(.horizontal)

            InputField(
                text: $inputText,
                placeHolderText: placeHolderText,
                minLines: minLines
            )

            Spacer()
            Spacer()

            HStack {
                Button {
                    isPresented = false
                } label: {
                    Text("Cancel")
                }
                .buttonStyle(.bordered)

                Button {
                    onConfirm?(inputText)
                    isPresented = false
                } label: {
                    Text("Continue")
                }
                .buttonStyle(.borderedProminent)
                .disabled(inputText.isEmpty)
            }
            .padding()
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }

    private struct InputField: View {
        @Binding var text: String
        var placeHolderText: LocalizedStringKey = "Enter message..."
        var minLines: Int = 1

        @FocusState private var isFocused: Bool

        var body: some View {
            TextField(placeHolderText, text: $text, axis: .vertical)
                .lineLimit(minLines...5)
                .focused($isFocused)
                .padding()
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(.primary, lineWidth: 1)
                )
                .padding(.horizontal)
                .padding(.vertical, 8)
        }
    }
}
