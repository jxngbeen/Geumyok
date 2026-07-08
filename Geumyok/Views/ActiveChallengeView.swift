import Foundation
import SwiftUI
#if os(iOS)
import UIKit
#endif

#if os(iOS)
struct KeyboardDoneTitleField: UIViewRepresentable {
    @Binding var text: String
    @Binding var isFocused: Bool
    let onDone: () -> Void

    func makeUIView(context: Context) -> UITextField {
        let textField = UITextField()
        textField.delegate = context.coordinator
        textField.returnKeyType = .done
        textField.textColor = .white
        textField.tintColor = .white
        textField.backgroundColor = .clear
        textField.borderStyle = .none
        textField.adjustsFontForContentSizeCategory = false
        textField.font = .systemFont(ofSize: 32, weight: .black)
        textField.inputAccessoryView = makeKeyboardDoneToolbar(
            target: context.coordinator,
            action: #selector(Coordinator.doneTapped)
        )
        textField.addTarget(
            context.coordinator,
            action: #selector(Coordinator.textChanged(_:)),
            for: .editingChanged
        )
        context.coordinator.textField = textField
        return textField
    }

    func updateUIView(_ textField: UITextField, context: Context) {
        context.coordinator.text = $text
        context.coordinator.isFocused = $isFocused
        context.coordinator.onDone = onDone

        if textField.text != text {
            textField.text = text
        }

        if isFocused, !textField.isFirstResponder {
            textField.becomeFirstResponder()
        } else if !isFocused, textField.isFirstResponder {
            textField.resignFirstResponder()
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text, isFocused: $isFocused, onDone: onDone)
    }

    final class Coordinator: NSObject, UITextFieldDelegate {
        var text: Binding<String>
        var isFocused: Binding<Bool>
        var onDone: () -> Void
        weak var textField: UITextField?

        init(text: Binding<String>, isFocused: Binding<Bool>, onDone: @escaping () -> Void) {
            self.text = text
            self.isFocused = isFocused
            self.onDone = onDone
        }

        @objc func textChanged(_ sender: UITextField) {
            text.wrappedValue = sender.text ?? ""
        }

        @objc func doneTapped() {
            onDone()
            textField?.resignFirstResponder()
        }

        func textFieldShouldReturn(_ textField: UITextField) -> Bool {
            onDone()
            textField.resignFirstResponder()
            return true
        }

        func textFieldDidBeginEditing(_ textField: UITextField) {
            isFocused.wrappedValue = true
        }

        func textFieldDidEndEditing(_ textField: UITextField) {
            isFocused.wrappedValue = false
        }
    }
}

#endif

struct EditableChallengeTitle: View {
    @ObservedObject var store: ChallengeStore
    let challenge: Challenge
    @State private var draftName = ""
    @State private var isEditing = false
    @State private var isFieldFocused = false
    @FocusState private var fallbackFocused: Bool

    var body: some View {
        Group {
            if isEditing {
#if os(iOS)
                KeyboardDoneTitleField(
                    text: $draftName,
                    isFocused: $isFieldFocused,
                    onDone: finishEditing
                )
                .frame(height: 42, alignment: .leading)
#else
                TextField("", text: $draftName)
                    .font(.system(size: 32, weight: .black))
                    .foregroundStyle(.white)
                    .focused($fallbackFocused)
                    .submitLabel(.done)
                    .onSubmit(finishEditing)
#endif
            } else {
                Text(challenge.name)
                    .font(.system(size: 32, weight: .black))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                    .onTapGesture(perform: beginEditing)
                    .accessibilityAddTraits(.isButton)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .onChange(of: draftName) { _, newValue in
            guard newValue.count > 24 else { return }
            draftName = String(newValue.prefix(24))
        }
        .onChange(of: isFieldFocused) { _, focused in
            if !focused, isEditing {
                finishEditing()
            }
        }
        .onChange(of: fallbackFocused) { _, focused in
            if !focused, isEditing {
                finishEditing()
            }
        }
    }

    private func beginEditing() {
        draftName = challenge.name
        isEditing = true
#if os(iOS)
        isFieldFocused = true
#else
        fallbackFocused = true
#endif
    }

    private func finishEditing() {
        guard isEditing else { return }
        if store.renameSelectedChallenge(to: draftName) {
            draftName = store.challenge?.name ?? challenge.name
        } else {
            draftName = challenge.name
        }
        isEditing = false
        isFieldFocused = false
        fallbackFocused = false
    }
}


struct ActiveChallengeView: View {
    @ObservedObject var store: ChallengeStore
    let challenge: Challenge
    @Binding var showingNewChallenge: Bool
    @State private var showingFailureConfirmation = false

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 28) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 6) {
                        EditableChallengeTitle(store: store, challenge: challenge)

                        Text("D+\(detailDayNumber) · 목표 \(challenge.targetDays)일")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.62))

                        Text(scheduleText)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.48))
                            .lineLimit(1)
                            .minimumScaleFactor(0.82)
                    }

                    Spacer()
                }
                .padding(.top, 34)

                ProgressRing(challenge: challenge)

                HStack(spacing: 10) {
                    StatPill(title: "성공", value: "\(challenge.successCount)일")
                    StatPill(title: "남은 날", value: "\(challenge.remainingDays)일")
                }

                if challenge.isActive {
                    VStack(spacing: 12) {
                        Button {
                            store.toggleTodaySuccess()
                        } label: {
                            Label(successButtonTitle, systemImage: "checkmark.circle.fill")
                                .font(.headline.weight(.bold))
                                .frame(maxWidth: .infinity)
                                .frame(height: 62)
                                .background(Color.mint)
                                .foregroundStyle(Color.black)
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)

                        Button {
                            showingFailureConfirmation = true
                        } label: {
                            Label("실패로 기록", systemImage: "xmark.circle.fill")
                                .font(.headline.weight(.bold))
                                .frame(maxWidth: .infinity)
                                .frame(height: 58)
                                .background(failureButtonBackground)
                                .foregroundStyle(failureButtonForeground)
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                        .disabled(hasSucceededToday)
                        .confirmationDialog(
                            "실패로 기록할까요?",
                            isPresented: $showingFailureConfirmation,
                            titleVisibility: .visible
                        ) {
                            Button("실패로 기록", role: .destructive) {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.86)) {
                                    store.recordToday(.failure)
                                }
                            }
                            Button("취소", role: .cancel) { }
                        } message: {
                            Text("이 금욕은 종료되고 지난 금욕에 저장됩니다.")
                        }
                    }
                } else {
                    ResultSummary(challenge: challenge, onRestart: restartAction)
                }

                Spacer(minLength: 18)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
            .frame(maxWidth: 520)
            .frame(maxWidth: .infinity)
        }
    }

    private var restartAction: (() -> Void)? {
        guard challenge.outcome == .failed else { return nil }
        return restartChallenge
    }

    private func restartChallenge() {
        store.prepareRestart(from: challenge)
        showingNewChallenge = true
    }

    private var successButtonTitle: String {
        hasSucceededToday ? "오늘 성공 수정" : "오늘 성공"
    }

    private var hasSucceededToday: Bool {
        store.todayStatus == .success
    }

    private var failureButtonBackground: Color {
        hasSucceededToday ? Color.white.opacity(0.04) : Color.white.opacity(0.08)
    }

    private var failureButtonForeground: Color {
        hasSucceededToday ? Color.red.opacity(0.32) : Color.red.opacity(0.92)
    }

    private var scheduleText: String {
        if let endedDate = challenge.endedDate, !challenge.isActive {
            return "시작 \(formattedDate(challenge.startDate)) · 종료 \(formattedDate(endedDate))"
        }

        return "시작 \(formattedDate(challenge.startDate)) · 종료 예정 \(formattedDate(expectedEndDate))"
    }

    private var detailDayNumber: Int {
        let start = Calendar.current.startOfDay(for: challenge.startDate)
        let end = Calendar.current.startOfDay(for: challenge.endedDate ?? Date())
        return max((Calendar.current.dateComponents([.day], from: start, to: end).day ?? 0) + 1, 1)
    }

    private var expectedEndDate: Date {
        let startDate = Calendar.current.startOfDay(for: challenge.startDate)
        return Calendar.current.date(
            byAdding: .day,
            value: max(challenge.targetDays - 1, 0),
            to: startDate
        ) ?? startDate
    }

    private func formattedDate(_ date: Date) -> String {
        Self.scheduleDateFormatter.string(from: date)
    }

    private static let scheduleDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy.MM.dd"
        return formatter
    }()
}


struct ResultSummary: View {
    let challenge: Challenge
    var onRestart: (() -> Void)? = nil

    var body: some View {
        Group {
            if let onRestart {
                Button {
                    onRestart()
                } label: {
                    summaryContent(showsChevron: true)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("같은 목표로 다시 시작")
            } else {
                summaryContent(showsChevron: false)
            }
        }
    }

    private func summaryContent(showsChevron: Bool) -> some View {
        HStack(spacing: 12) {
            Image(systemName: iconName)
                .font(.title2.weight(.bold))
                .foregroundStyle(iconColor)
                .frame(width: 44, height: 44)
                .background(Color.white.opacity(0.08))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline.weight(.black))
                Text(subtitle)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.58))
            }

            Spacer()

            if showsChevron {
                Image(systemName: "chevron.right")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.white.opacity(0.34))
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.card, style: .continuous))
    }

    private var title: String {
        challenge.outcome == .completed ? "목표 달성" : "다시 시작해볼까요?"
    }

    private var subtitle: String {
        if challenge.outcome == .failed {
            return "같은 목표로 새로 시작해요"
        }

        return "\(challenge.successCount)일을 기록했어요"
    }

    private var iconName: String {
        challenge.outcome == .completed ? "trophy.fill" : "arrow.clockwise"
    }

    private var iconColor: Color {
        challenge.outcome == .completed ? .orange : .mint
    }
}


