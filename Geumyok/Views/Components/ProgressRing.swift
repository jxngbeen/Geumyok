import Foundation
import SwiftUI
#if os(iOS)
import UIKit
#endif

struct ProgressRing: View {
    let challenge: Challenge

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.08), lineWidth: 22)

            Circle()
                .trim(from: 0, to: challenge.progress)
                .stroke(
                    Color.mint,
                    style: StrokeStyle(lineWidth: 22, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.32), value: challenge.progress)

            VStack(spacing: 8) {
                Text("\(challenge.successCount)")
                    .font(.system(size: 76, weight: .black, design: .rounded))
                    .contentTransition(.numericText())

                Text("일 성공")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.white.opacity(0.68))
            }
        }
        .frame(width: 248, height: 248)
        .padding(.vertical, 10)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(challenge.successCount)일 성공")
    }
}

struct StatPill: View {
    let title: String
    let value: String

    var body: some View {
        VStack(spacing: 6) {
            Text(title)
                .font(.caption.weight(.bold))
                .foregroundStyle(.white.opacity(0.5))
            Text(value)
                .font(.headline.weight(.black))
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Color.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.input, style: .continuous))
    }
}


