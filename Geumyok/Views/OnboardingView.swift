import Foundation
import SwiftUI
#if os(iOS)
import UIKit
#endif

struct IntroSplashView: View {
    let showsContent: Bool
    let isVisible: Bool

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()

            if showsContent {
                VStack(spacing: 18) {
                    ZStack {
                        Circle()
                            .stroke(Color.mint.opacity(0.24), lineWidth: 8)
                        Circle()
                            .trim(from: 0.08, to: 0.86)
                            .stroke(Color.mint, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                        Image(systemName: "flame.fill")
                            .font(.system(size: 34, weight: .bold))
                            .foregroundStyle(.white)
                    }
                    .frame(width: 86, height: 86)

                    VStack(spacing: 8) {
                        Text("금욕")
                            .font(.system(size: 42, weight: .black))
                            .foregroundStyle(.white)

                        Text("오늘 하루를 지켜내는 기록")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.58))
                    }
                }
                .opacity(isVisible ? 1 : 0)
                .scaleEffect(isVisible ? 1 : 0.96)
                .animation(.easeOut(duration: 0.3), value: isVisible)
            }
        }
    }
}

struct OnboardingTutorialView: View {
    let onDone: () -> Void

    var body: some View {
        ZStack {
            AppBackground()

            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("처음 시작하기")
                        .font(.title.weight(.black))

                    Text("목표를 만들고 하루에 한 번만 기록하세요.")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.62))
                }

                VStack(spacing: 16) {
                    OnboardingStepRow(
                        iconName: "plus.circle.fill",
                        title: "금욕 만들기",
                        message: "목표명과 목표 일수를 정해요."
                    )
                    OnboardingStepRow(
                        iconName: "checkmark.circle.fill",
                        title: "오늘 성공",
                        message: "하루가 끝나면 성공을 기록해요."
                    )
                    OnboardingStepRow(
                        iconName: "clock.arrow.circlepath",
                        title: "지난 금욕",
                        message: "끝난 기록은 목록에서 다시 볼 수 있어요."
                    )
                }

                Spacer(minLength: 8)

                Button {
                    onDone()
                } label: {
                    Text("시작하기")
                        .font(.headline.weight(.bold))
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.mint)
                        .foregroundStyle(Color.black)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
            .padding(24)
            .frame(maxWidth: 520, maxHeight: .infinity, alignment: .topLeading)
        }
        .preferredColorScheme(.dark)
    }
}

struct OnboardingStepRow: View {
    let iconName: String
    let title: String
    let message: String

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: iconName)
                .font(.title3.weight(.bold))
                .foregroundStyle(.mint)
                .frame(width: 38, height: 38)
                .background(Color.white.opacity(0.08))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.headline.weight(.black))
                    .foregroundStyle(.white)
                Text(message)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.58))
            }

            Spacer()
        }
    }
}


