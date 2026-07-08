import Foundation
import SwiftUI
#if os(iOS)
import UIKit
#endif

struct ChallengeRow: View {
    let challenge: Challenge
    var isSelecting = false
    var isSelected = false

    var body: some View {
        HStack(spacing: 14) {
            if isSelecting {
                selectionIndicator
            }

            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.1), lineWidth: 5)
                Circle()
                    .trim(from: 0, to: challenge.progress)
                    .stroke(Color.mint, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                Text("\(Int(challenge.progress * 100))%")
                    .font(.caption2.weight(.black))
                    .foregroundStyle(.white.opacity(0.82))
            }
            .frame(width: 52, height: 52)

            VStack(alignment: .leading, spacing: 5) {
                Text(challenge.name)
                    .font(.headline.weight(.black))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                Text("\(challenge.successCount)일 성공 · 목표 \(challenge.targetDays)일")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.58))
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }

            Spacer()

            if !isSelecting {
                trailingAccessory
            }
        }
        .padding(16)
        .background(Color.white.opacity(isSelected ? 0.12 : 0.08))
        .overlay {
            RoundedRectangle(cornerRadius: AppCornerRadius.card, style: .continuous)
                .stroke(isSelected ? Color.red.opacity(0.34) : Color.clear, lineWidth: 1)
                .allowsHitTesting(false)
        }
        .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.card, style: .continuous))
        .animation(.easeOut(duration: 0.16), value: isSelecting)
        .animation(.easeOut(duration: 0.16), value: isSelected)
    }

    private var selectionIndicator: some View {
        Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
            .font(.title3.weight(.bold))
            .foregroundStyle(isSelected ? Color.red.opacity(0.92) : Color.white.opacity(0.34))
            .frame(width: 28, height: 28)
    }

    private var trailingAccessory: some View {
        HStack(spacing: 8) {
            if !challenge.isActive {
                Image(systemName: resultIconName)
                    .foregroundStyle(resultColor)
            }

            Image(systemName: "chevron.right")
                .foregroundStyle(.white.opacity(0.34))
        }
        .font(.headline.weight(.bold))
    }

    private var resultIconName: String {
        challenge.outcome == .completed ? "trophy.fill" : "xmark.circle.fill"
    }

    private var resultColor: Color {
        challenge.outcome == .completed ? .orange : .red.opacity(0.82)
    }
}


