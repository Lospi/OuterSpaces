//
//  Utilities.swift
//  Outer Spaces
//
//  Created by Roberto Camargo on 25/03/25.
//

import SFSafeSymbols
import SwiftUI

struct EmptyStateView: View {
    var icon: SFSymbol
    var title: String
    var subtitle: String
    var buttonTitle: String
    var action: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemSymbol: icon)
                .font(.system(size: 40))
                .foregroundStyle(.secondary)

            Text(title)
                .font(.headline)

            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button(action: action) {
                Text(buttonTitle)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .frame(maxWidth: .infinity)
    }
}

struct SuccessAnimationView: View {
    @State private var opacity: CGFloat = 0

    var body: some View {
        VStack {
            Spacer()

            HStack(spacing: 8) {
                Image(systemSymbol: .checkmarkCircleFill)
                    .foregroundStyle(.green)
                Text("Spaces updated")
                    .font(.callout.weight(.medium))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .opacity(opacity)
        }
        .padding(.bottom, 8)
        .allowsHitTesting(false)
        .onAppear {
            withAnimation(.easeIn(duration: 0.2)) {
                opacity = 1.0
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                withAnimation(.easeOut(duration: 0.3)) {
                    opacity = 0
                }
            }
        }
    }
}
