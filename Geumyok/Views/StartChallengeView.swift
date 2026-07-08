import Foundation
import SwiftUI
#if os(iOS)
import UIKit
#endif

struct StartChallengeView: View {
    @ObservedObject var store: ChallengeStore
    var onStarted: (() -> Void)? = nil
    @Environment(\.dismiss) private var dismiss
    @State private var showingMissingNameAlert = false

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

                VStack(alignment: .leading, spacing: 18) {
                    Text("목표명")
                        .font(.headline)
                        .foregroundStyle(.white.opacity(0.82))

                    ChallengeNameField(name: $store.selectedChallengeName)
                }

                VStack(alignment: .leading, spacing: 18) {
                    Text("목표 일수")
                        .font(.headline)
                        .foregroundStyle(.white.opacity(0.82))

                    TargetDayNumberField(selection: $store.selectedTargetDays)

                    TargetDayWheel(selection: $store.selectedTargetDays)
                }

                Button {
                    guard hasChallengeName else {
                        showingMissingNameAlert = true
                        return
                    }

                    withAnimation(.spring(response: 0.35, dampingFraction: 0.86)) {
                        if store.startChallenge(
                            name: store.selectedChallengeName,
                            targetDays: store.selectedTargetDays
                        ) {
                            onStarted?()
                            dismiss()
                        }
                    }
                } label: {
                    Label("금욕 시작하기", systemImage: "flame.fill")
                        .font(.headline.weight(.bold))
                        .frame(maxWidth: .infinity)
                        .frame(height: 62)
                        .background(Color.mint)
                        .foregroundStyle(Color.black)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .alert("목표명을 설정해주세요", isPresented: $showingMissingNameAlert) {
                    Button("좋아요", role: .cancel) { }
                } message: {
                    Text("이 금욕을 뭐라고 부를지 먼저 정해볼까요?")
                }

                Spacer(minLength: 18)
            }
            .padding(.horizontal, 24)
            .frame(maxWidth: 520)
            .frame(maxWidth: .infinity)
        }
    }

    private var hasChallengeName: Bool {
        !store.selectedChallengeName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

struct ChallengeNameField: View {
    @Binding var name: String

    var body: some View {
        Group {
#if os(iOS)
            KeyboardDoneNameField(text: $name)
#else
            TextField("예: 금연, 야식 끊기", text: $name)
                .font(.title3.weight(.bold))
                .foregroundStyle(.white)
                .submitLabel(.done)
#endif
        }
        .padding(.horizontal, 16)
        .frame(height: 56)
        .background(Color.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.input, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: AppCornerRadius.input, style: .continuous)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                .allowsHitTesting(false)
        }
        .onChange(of: name) { _, newValue in
            guard newValue.count > 24 else { return }
            name = String(newValue.prefix(24))
        }
        .accessibilityLabel("목표명 입력")
    }
}

struct TargetDayNumberField: View {
    @Binding var selection: Int
    @State private var text: String
    @State private var isFocused = false

    init(selection: Binding<Int>) {
        self._selection = selection
        self._text = State(initialValue: "\(selection.wrappedValue)")
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 4) {
#if os(iOS)
            KeyboardDoneNumberField(
                text: $text,
                isFocused: $isFocused,
                onDone: finishEditing
            )
            .frame(width: numberFieldWidth, height: 74, alignment: .leading)
            .animation(.easeOut(duration: 0.12), value: numberFieldWidth)
            .accessibilityLabel("목표 일수 입력")
#else
            TextField("30", text: $text)
                .font(.system(size: 64, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
                .frame(width: numberFieldWidth, alignment: .leading)
                .animation(.easeOut(duration: 0.12), value: numberFieldWidth)
                .multilineTextAlignment(.leading)
                .accessibilityLabel("목표 일수 입력")
#endif

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

    private func finishEditing() {
        normalizeText()
        isFocused = false
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

struct TargetDayWheel: View {
    @Binding var selection: Int

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: AppCornerRadius.input, style: .continuous)
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
        .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.input, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: AppCornerRadius.input, style: .continuous)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                .allowsHitTesting(false)
        }
        .accessibilityLabel("목표 일수 선택")
        .accessibilityValue("\(selection)일")
    }
}


#if os(iOS)
func makeKeyboardDoneToolbar(target: Any?, action: Selector) -> UIToolbar {
    let toolbar = UIToolbar()
    toolbar.sizeToFit()
    toolbar.tintColor = .white

    let spacer = UIBarButtonItem(systemItem: .flexibleSpace)
    let done = UIBarButtonItem(
        title: "완료",
        style: .plain,
        target: target,
        action: action
    )
    let attributes: [NSAttributedString.Key: Any] = [
        .foregroundColor: UIColor.white,
        .font: UIFont.systemFont(ofSize: 17, weight: .semibold)
    ]
    done.setTitleTextAttributes(attributes, for: .normal)
    done.setTitleTextAttributes(attributes, for: .highlighted)
    toolbar.items = [spacer, done]
    return toolbar
}

#endif

#if os(iOS)
struct KeyboardDoneNameField: UIViewRepresentable {
    @Binding var text: String

    func makeUIView(context: Context) -> UITextField {
        let textField = UITextField()
        textField.delegate = context.coordinator
        textField.placeholder = "예: 금연, 야식 끊기"
        textField.returnKeyType = .done
        textField.textColor = .white
        textField.tintColor = .white
        textField.backgroundColor = .clear
        textField.borderStyle = .none
        textField.font = .systemFont(ofSize: 20, weight: .bold)
        textField.attributedPlaceholder = NSAttributedString(
            string: "예: 금연, 야식 끊기",
            attributes: [.foregroundColor: UIColor.white.withAlphaComponent(0.34)]
        )
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

        if textField.text != text {
            textField.text = text
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text)
    }

    final class Coordinator: NSObject, UITextFieldDelegate {
        var text: Binding<String>
        weak var textField: UITextField?

        init(text: Binding<String>) {
            self.text = text
        }

        @objc func textChanged(_ sender: UITextField) {
            text.wrappedValue = sender.text ?? ""
        }

        @objc func doneTapped() {
            textField?.resignFirstResponder()
        }

        func textFieldShouldReturn(_ textField: UITextField) -> Bool {
            textField.resignFirstResponder()
            return true
        }
    }
}

#endif

#if os(iOS)
struct KeyboardDoneNumberField: UIViewRepresentable {
    @Binding var text: String
    @Binding var isFocused: Bool
    let onDone: () -> Void

    func makeUIView(context: Context) -> UITextField {
        let textField = UITextField()
        textField.delegate = context.coordinator
        textField.keyboardType = .numberPad
        textField.textColor = .white
        textField.tintColor = .white
        textField.textAlignment = .left
        textField.backgroundColor = .clear
        textField.borderStyle = .none
        textField.adjustsFontForContentSizeCategory = false
        textField.font = roundedFont(size: 64, weight: .heavy)
        textField.inputAccessoryView = context.coordinator.makeToolbar()
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

    private func roundedFont(size: CGFloat, weight: UIFont.Weight) -> UIFont {
        let font = UIFont.systemFont(ofSize: size, weight: weight)
        guard let descriptor = font.fontDescriptor.withDesign(.rounded) else { return font }
        return UIFont(descriptor: descriptor, size: size)
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

        func makeToolbar() -> UIToolbar {
            makeKeyboardDoneToolbar(target: self, action: #selector(doneTapped))
        }

        @objc func textChanged(_ sender: UITextField) {
            text.wrappedValue = sender.text ?? ""
        }

        @objc func doneTapped() {
            onDone()
            textField?.resignFirstResponder()
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

#if os(iOS)
struct NativeDayWheelPicker: UIViewRepresentable {
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

