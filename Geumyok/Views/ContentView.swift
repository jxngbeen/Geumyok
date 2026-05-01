import SwiftUI

struct ContentView: View {
    @StateObject private var store = ChallengeStore()

    var body: some View {
        ZStack {
            AppBackground()

            if let challenge = store.challenge, challenge.isActive {
                ActiveChallengeView(store: store, challenge: challenge)
            } else {
                StartChallengeView(store: store)
            }
        }
        .preferredColorScheme(.dark)
    }
}

private struct StartChallengeView: View {
    @ObservedObject var store: ChallengeStore

    private let presets = [7, 14, 30, 66, 100]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("금욕")
                        .font(.system(size: 42, weight: .black))

                    Text("오늘부터 쌓는 조용한 기록")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.72))
                }
                .padding(.top, 44)

                if let challenge = store.challenge, store.hasFinishedChallenge {
                    ResultSummary(challenge: challenge)
                }

                VStack(alignment: .leading, spacing: 18) {
                    Text("목표 일수")
                        .font(.headline)
                        .foregroundStyle(.white.opacity(0.82))

                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text("\(store.selectedTargetDays)")
                            .font(.system(size: 64, weight: .heavy, design: .rounded))
                            .contentTransition(.numericText())
                        Text("일")
                            .font(.title2.weight(.bold))
                            .foregroundStyle(.white.opacity(0.72))
                    }

                    Stepper(value: $store.selectedTargetDays, in: 1...365, step: 1) {
                        Text("하루씩 조정")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.68))
                    }
                    .tint(.mint)

                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 5), spacing: 10) {
                        ForEach(presets, id: \.self) { day in
                            Button {
                                withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                                    store.selectedTargetDays = day
                                }
                            } label: {
                                Text("\(day)")
                                    .font(.callout.weight(.bold))
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 44)
                                    .background(store.selectedTargetDays == day ? Color.mint.opacity(0.95) : Color.white.opacity(0.09))
                                    .foregroundStyle(store.selectedTargetDays == day ? Color.black : Color.white)
                                    .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.86)) {
                        store.startChallenge(targetDays: store.selectedTargetDays)
                    }
                } label: {
                    Label("도전 시작하기", systemImage: "flame.fill")
                        .font(.headline.weight(.bold))
                        .frame(maxWidth: .infinity)
                        .frame(height: 62)
                        .background(Color.mint)
                        .foregroundStyle(Color.black)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)

                Spacer(minLength: 18)
            }
            .padding(.horizontal, 24)
            .frame(maxWidth: 520)
            .frame(maxWidth: .infinity)
        }
    }
}

private struct ActiveChallengeView: View {
    @ObservedObject var store: ChallengeStore
    let challenge: Challenge

    var body: some View {
        VStack(spacing: 26) {
            HStack {
                VStack(alignment: .leading, spacing: 5) {
                    Text("금욕")
                        .font(.title.weight(.black))
                    Text("D+\(store.dayNumber) · 목표 \(challenge.targetDays)일")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.62))
                }

                Spacer()

                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.86)) {
                        store.resetChallenge()
                    }
                } label: {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.headline.weight(.bold))
                        .frame(width: 44, height: 44)
                        .background(Color.white.opacity(0.1))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("도전 초기화")
            }

            Spacer(minLength: 12)

            ProgressRing(progress: challenge.progress, successCount: challenge.successCount)
                .frame(width: 280, height: 280)

            HStack(spacing: 10) {
                StatPill(title: "성공", value: "\(challenge.successCount)일", color: .mint)
                StatPill(title: "남은 날", value: "\(challenge.remainingDays)일", color: .cyan)
                StatPill(title: "진행률", value: "\(Int(challenge.progress * 100))%", color: .orange)
            }

            Spacer(minLength: 10)

            VStack(spacing: 12) {
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.86)) {
                        store.recordToday(.success)
                    }
                } label: {
                    Label(successButtonTitle, systemImage: "checkmark.circle.fill")
                        .font(.headline.weight(.bold))
                        .frame(maxWidth: .infinity)
                        .frame(height: 62)
                        .background(successButtonBackground)
                        .foregroundStyle(successButtonForeground)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .disabled(store.todayStatus == .success)

                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.86)) {
                        store.recordToday(.failure)
                    }
                } label: {
                    Label("실패 기록", systemImage: "xmark.circle")
                        .font(.headline.weight(.bold))
                        .frame(maxWidth: .infinity)
                        .frame(height: 58)
                        .overlay(
                            Capsule()
                                .stroke(Color.red.opacity(0.55), lineWidth: 1.5)
                        )
                        .foregroundStyle(.red.opacity(0.9))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 26)
        .padding(.bottom, 28)
        .frame(maxWidth: 520)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var successButtonTitle: String {
        store.todayStatus == .success ? "오늘 성공 완료" : "오늘 성공"
    }

    private var successButtonBackground: Color {
        store.todayStatus == .success ? Color.white.opacity(0.12) : Color.mint
    }

    private var successButtonForeground: Color {
        store.todayStatus == .success ? Color.white.opacity(0.56) : Color.black
    }
}

private struct ProgressRing: View {
    let progress: Double
    let successCount: Int

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.1), lineWidth: 22)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    AngularGradient(
                        colors: [.mint, .cyan, .orange, .mint],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 22, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 0.5, dampingFraction: 0.85), value: progress)

            VStack(spacing: 2) {
                Text("\(successCount)")
                    .font(.system(size: 78, weight: .black, design: .rounded))
                    .contentTransition(.numericText())
                Text("일 성공")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.white.opacity(0.68))
            }
        }
        .padding(12)
    }
}

private struct StatPill: View {
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white.opacity(0.54))
            Text(value)
                .font(.headline.weight(.black))
                .foregroundStyle(color)
                .minimumScaleFactor(0.78)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 72)
        .background(Color.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

private struct ResultSummary: View {
    let challenge: Challenge

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: challenge.outcome == .completed ? "trophy.fill" : "flag.checkered")
                .font(.title2.weight(.bold))
                .foregroundStyle(challenge.outcome == .completed ? Color.orange : Color.red.opacity(0.88))
                .frame(width: 44, height: 44)
                .background(Color.white.opacity(0.09))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(challenge.outcome == .completed ? "목표를 달성했어요" : "이전 도전이 끝났어요")
                    .font(.headline.weight(.bold))
                Text("\(challenge.successCount)일 성공 · 목표 \(challenge.targetDays)일")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.62))
            }

            Spacer()
        }
        .padding(16)
        .background(Color.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

private struct AppBackground: View {
    var body: some View {
        LinearGradient(
            colors: [
                Color(red: 0.05, green: 0.07, blue: 0.09),
                Color(red: 0.08, green: 0.11, blue: 0.13),
                Color(red: 0.05, green: 0.06, blue: 0.08)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
}

private struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
