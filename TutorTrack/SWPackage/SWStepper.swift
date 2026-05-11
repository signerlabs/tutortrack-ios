//
//  SWStepper.swift
//  TutorTrack — ShipSwift Recipe: component-stepper
//
//  Compact 数字 stepper：chevron ± 按钮、numericText 动画、haptic 反馈。
//  quantity ≤ 0 时 decrement 自动 disabled。
//

import SwiftUI

struct SWStepper: View {
    @Binding var quantity: Int

    var body: some View {
        HStack {
            Button {
                quantity -= 1
            } label: {
                Image(systemName: "chevron.backward")
                    .imageScale(.large)
            }
            .disabled(quantity <= 0)
            .buttonStyle(.plain)

            Text("\(quantity)")
                .frame(minWidth: 26)
                .contentTransition(.numericText())

            Button {
                quantity += 1
            } label: {
                Image(systemName: "chevron.forward")
                    .imageScale(.large)
            }
            .buttonStyle(.plain)
        }
        .animation(.default, value: quantity)
        .sensoryFeedback(.increase, trigger: [quantity])
    }
}
