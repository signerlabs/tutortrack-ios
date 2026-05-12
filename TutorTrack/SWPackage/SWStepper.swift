//
//  SWStepper.swift
//  TutorTrack — ShipSwift Recipe: component-stepper
//
//  Compact numeric stepper: chevron +/- buttons, numericText animation,
//  haptic feedback. The decrement button auto-disables when quantity <= 0.
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
