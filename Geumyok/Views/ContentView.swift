import SwiftUI
#if os(iOS)
import UIKit
#endif

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

                    TargetDayNumberField(selection: $store.selectedTargetDays)

                    TargetDayWheel(selection: $store.selectedTargetDays)
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

private struct TargetDayNumberField: View {
    @Binding var selection: Int
    @State private var text: String
    @FocusState private var isFocused: Bool

    init(selection: Binding<Int>) {
        self._selection = selection
        self._text = State(initialValue: "\(selection.wrappedValue)")
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 4) {
            TextField("30", text: $text)
                .font(.system(size: 64, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
                .focused($isFocused)
                .frame(width: numberFieldWidth, alignment: .leading)
                .animation(.easeOut(duration: 0.12), value: numberFieldWidth)
                .multilineTextAlignment(.leading)
#if os(iOS)
                .keyboardType(.numberPad)
                .toolbar {
                    ToolbarItemGroup(placement: .keyboard) {
                        Spacer()
                        Button("완료") {
                            isFocused = false
                        }
                    }
                }
#endif
                .accessibilityLabel("목표 일수 입력")

            Text("일")
                .font(.title2.weight(.bold))
                .foregroundStyle(.white.opacity(0.72))
        }
        .onChange(of: text) { _, newValue in
            syncSelection(with: newValue)
        }
        .onChange(of: selection) { _, newValue in
            guard !isFocused else { return }
            text = "\(newValue)"
        }
        .onChange(of: isFocused) { _, focused in
            guard !focused else { return }
            normalizeText()
        }
    }

    private var numberFieldWidth: CGFloat {
        let visibleText = text.isEmpty ? "\(selection)" : text
        let digitCount = max(visibleText.count, 1)
        return min(max(CGFloat(digitCount) * 40 + 8, 48), 132)
    }

    private func syncSelection(with value: String) {
        let filtered = String(value.filter { $0.isNumber }.prefix(3))
        guard filtered == value else {
            text = filtered
            return
        }

        guard let number = Int(filtered) else { return }
        let clamped = min(max(number, 1), 365)
        selection = clamped

        if clamped != number {
            text = "\(clamped)"
        }
    }

    private func normalizeText() {
        guard let number = Int(text) else {
            text = "\(selection)"
            return
        }

        let clamped = min(max(number, 1), 365)
        selection = clamped
        text = "\(clamped)"
    }
}

private struct TargetDayWheel: View {
    @Binding var selection: Int

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color.white.opacity(0.08))

#if os(iOS)
            NativeDayWheelPicker(selection: $selection)
                .frame(height: 184)
#else
            Picker("목표 일수", selection: $selection) {
                ForEach(1...365, id: \.self) { day in
                    Text("\(day)일")
                        .tag(day)
                }
            }
            .labelsHidden()
            .frame(height: 184)
#endif
        }
        .frame(height: 184)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                .allowsHitTesting(false)
        }
        .accessibilityLabel("목표 일수 선택")
        .accessibilityValue("\(selection)일")
    }
}

#if os(iOS)
private struct NativeDayWheelPicker: UIViewRepresentable {
    @Binding var selection: Int

    func makeUIView(context: Context) -> UIPickerView {
        let pickerView = UIPickerView()
        pickerView.backgroundColor = .clear
        pickerView.dataSource = context.coordinator
        pickerView.delegate = context.coordinator
        pickerView.selectRow(clamped(selection) - 1, inComponent: 0, animated: false)
        return pickerView
    }

    func updateUIView(_ pickerView: UIPickerView, context: Context) {
        context.coordinator.selection = $selection

        let row = clamped(selection) - 1
        if pickerView.selectedRow(inComponent: 0) != row {
            pickerView.selectRow(row, inComponent: 0, animated: true)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(selection: $selection)
    }

    private func clamped(_ value: Int) -> Int {
        min(max(value, 1), 365)
    }

    final class Coordinator: NSObject, UIPickerViewDataSource, UIPickerViewDelegate {
        var selection: Binding<Int>

        init(selection: Binding<Int>) {
            self.selection = selection
        }

        func numberOfComponents(in pickerView: UIPickerView) -> Int {
            1
        }

        func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
            365
        }

        func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
            44
        }

        func pickerView(_ pickerView: UIPickerView, widthForComponent component: Int) -> CGFloat {
            pickerView.bounds.width
        }

        func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
            selection.wrappedValue = row + 1
        }

        func pickerView(_ pickerView: UIPickerView, attributedTitleForRow row: Int, forComponent component: Int) -> NSAttributedString? {
            NSAttributedString(
                string: "\(row + 1)일",
                attributes: [
                    .font: UIFont.systemFont(ofSize: 22, weight: .semibold),
                    .foregroundColor: UIColor.white.withAlphaComponent(0.86)
                ]
            )
        }
    }
}
#endif

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
