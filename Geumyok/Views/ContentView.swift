import SwiftUI
#if os(iOS)
import UIKit
#endif

struct ContentView: View {
    @StateObject private var store = ChallengeStore()
    @State private var selectedTab: MainTab = .home

    var body: some View {
        ZStack {
            AppBackground()

            if store.challenge != nil {
                DetailTabView(store: store, selectedTab: $selectedTab)
            } else {
                HomeOnlyTabView(store: store, selectedTab: $selectedTab)
            }
        }
        .onChange(of: store.selectedChallengeID) { _, newValue in
            selectedTab = newValue == nil ? .home : .detail
        }
        .preferredColorScheme(.dark)
    }
}

private enum MainTab: Hashable {
    case home
    case detail
}

private struct HomeOnlyTabView: View {
    @ObservedObject var store: ChallengeStore
    @Binding var selectedTab: MainTab

    var body: some View {
        TabView(selection: $selectedTab) {
            ChallengeDashboardView(store: store) { challenge in
                store.selectChallenge(challenge)
            }
            .tabItem {
                Label("홈", systemImage: "list.bullet")
            }
            .tag(MainTab.home)
        }
        .tint(.mint)
        .onAppear {
            selectedTab = .home
        }
    }
}

private struct DetailTabView: View {
    @ObservedObject var store: ChallengeStore
    @Binding var selectedTab: MainTab

    var body: some View {
        TabView(selection: $selectedTab) {
            ChallengeDashboardView(store: store) { challenge in
                store.selectChallenge(challenge)
                selectedTab = .detail
            }
            .tabItem {
                Label("홈", systemImage: "list.bullet")
            }
            .tag(MainTab.home)

            if let challenge = store.challenge {
                ActiveChallengeView(store: store, challenge: challenge)
                    .tabItem {
                        Label(challenge.name, systemImage: "circle.circle.fill")
                    }
                    .tag(MainTab.detail)
            }
        }
        .tint(.mint)
        .onAppear {
            selectedTab = .detail
        }
    }
}

private struct ChallengeDashboardView: View {
    @ObservedObject var store: ChallengeStore
    let onSelect: (Challenge) -> Void
    @State private var showingNewChallenge = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    dashboardHeader
                        .listRowInsets(EdgeInsets(top: 32, leading: 24, bottom: 18, trailing: 24))
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                }

                if store.challenges.isEmpty {
                    EmptyChallengeList {
                        showingNewChallenge = true
                    }
                    .listRowInsets(EdgeInsets(top: 0, leading: 24, bottom: 8, trailing: 24))
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                } else {
                    ChallengeSection(
                        title: "진행 중",
                        challenges: store.activeChallenges,
                        emptyText: "진행 중인 도전이 없어요",
                        store: store,
                        onSelect: onSelect
                    )

                    ChallengeSection(
                        title: "지난 도전",
                        challenges: store.finishedChallenges,
                        emptyText: "아직 끝난 도전이 없어요",
                        store: store,
                        onSelect: { _ in }
                    )
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(Color.clear)
            .sheet(isPresented: $showingNewChallenge) {
                StartChallengeView(store: store) {
                    showingNewChallenge = false
                }
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
            }
        }
    }

    private var dashboardHeader: some View {
        HStack(alignment: .top, spacing: 18) {
            VStack(alignment: .leading, spacing: 10) {
                Text("금욕")
                    .font(.system(size: 42, weight: .black))

                Text("오늘 이어갈 도전을 골라주세요")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.72))
            }

            Spacer()

            Button {
                showingNewChallenge = true
            } label: {
                Image(systemName: "plus")
                    .font(.headline.weight(.black))
                    .frame(width: 44, height: 44)
                    .background(Color.mint)
                    .foregroundStyle(Color.black)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("금욕 만들기")
        }
    }
}

private struct EmptyChallengeList: View {
    let onCreate: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Image(systemName: "flag")
                .font(.title.weight(.bold))
                .foregroundStyle(.mint)
                .frame(width: 48, height: 48)
                .background(Color.white.opacity(0.08))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 8) {
                Text("아직 도전이 없어요")
                    .font(.title2.weight(.black))
                Text("금연, 야식 끊기, SNS 줄이기처럼 따로 관리할 목표를 만들어보세요.")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.62))
            }

            Button {
                onCreate()
            } label: {
                Label("첫 도전 만들기", systemImage: "plus.circle.fill")
                    .font(.headline.weight(.bold))
                    .frame(maxWidth: .infinity)
                    .frame(height: 58)
                    .background(Color.mint)
                    .foregroundStyle(Color.black)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(18)
        .background(Color.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

private struct ChallengeSection: View {
    let title: String
    let challenges: [Challenge]
    let emptyText: String
    @ObservedObject var store: ChallengeStore
    let onSelect: (Challenge) -> Void

    var body: some View {
        Section {
            if challenges.isEmpty {
                Text(emptyText)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.52))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .background(Color.white.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .listRowInsets(EdgeInsets(top: 5, leading: 24, bottom: 5, trailing: 24))
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
            } else {
                ForEach(challenges) { challenge in
                    Button {
                        guard challenge.isActive else { return }
                        onSelect(challenge)
                    } label: {
                        ChallengeRow(challenge: challenge)
                    }
                    .buttonStyle(.plain)
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.86)) {
                                store.deleteChallenge(challenge)
                            }
                        } label: {
                            Label("삭제", systemImage: "trash")
                        }
                        .tint(.red)
                    }
                    .listRowInsets(EdgeInsets(top: 5, leading: 24, bottom: 5, trailing: 24))
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                }
            }
        } header: {
            Text(title)
                .font(.headline)
                .foregroundStyle(.white.opacity(0.82))
                .textCase(nil)
                .padding(.horizontal, 8)
        }
    }
}

private struct ChallengeRow: View {
    let challenge: Challenge

    var body: some View {
        HStack(spacing: 14) {
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

            Image(systemName: challenge.isActive ? "chevron.right" : resultIconName)
                .font(.headline.weight(.bold))
                .foregroundStyle(challenge.isActive ? .white.opacity(0.34) : resultColor)
        }
        .padding(16)
        .background(Color.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private var resultIconName: String {
        challenge.outcome == .completed ? "trophy.fill" : "xmark.circle.fill"
    }

    private var resultColor: Color {
        challenge.outcome == .completed ? .orange : .red.opacity(0.82)
    }
}

private struct StartChallengeView: View {
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

                if let challenge = store.challenge, store.hasFinishedChallenge {
                    ResultSummary(challenge: challenge)
                }

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
                    Label("도전 시작하기", systemImage: "flame.fill")
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
                    Text("이 도전을 뭐라고 부를지 먼저 정해볼까요?")
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

private struct ChallengeNameField: View {
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
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
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

private struct TargetDayNumberField: View {
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
private func makeKeyboardDoneToolbar(target: Any?, action: Selector) -> UIToolbar {
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

private struct KeyboardDoneNameField: UIViewRepresentable {
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

private struct KeyboardDoneNumberField: UIViewRepresentable {
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
        ScrollView {
            VStack(spacing: 28) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(challenge.name)
                            .font(.system(size: 32, weight: .black))
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)

                        Text("D+\(store.dayNumber) · 목표 \(challenge.targetDays)일")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.62))
                    }

                    Spacer()

                    Button(role: .destructive) {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.86)) {
                            store.resetChallenge()
                        }
                    } label: {
                        Image(systemName: "trash")
                            .font(.headline.weight(.bold))
                            .frame(width: 42, height: 42)
                            .background(Color.white.opacity(0.08))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.red.opacity(0.9))
                    .accessibilityLabel("도전 삭제")
                }
                .padding(.top, 34)

                ProgressRing(challenge: challenge)

                HStack(spacing: 10) {
                    StatPill(title: "성공", value: "\(challenge.successCount)일")
                    StatPill(title: "남은 날", value: "\(challenge.remainingDays)일")
                }

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
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.86)) {
                            store.recordToday(.failure)
                        }
                    } label: {
                        Label("실패로 기록", systemImage: "xmark.circle.fill")
                            .font(.headline.weight(.bold))
                            .frame(maxWidth: .infinity)
                            .frame(height: 58)
                            .background(Color.white.opacity(0.08))
                            .foregroundStyle(.white)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }

                Spacer(minLength: 18)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
            .frame(maxWidth: 520)
            .frame(maxWidth: .infinity)
        }
    }

    private var successButtonTitle: String {
        store.todayStatus == .success ? "오늘 성공 수정" : "오늘 성공"
    }
}

private struct ProgressRing: View {
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

private struct StatPill: View {
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
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

private struct ResultSummary: View {
    let challenge: Challenge

    var body: some View {
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
                Text("\(challenge.successCount)일을 기록했어요")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.58))
            }

            Spacer()
        }
        .padding(16)
        .background(Color.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private var title: String {
        challenge.outcome == .completed ? "목표 달성" : "다시 시작해볼까요?"
    }

    private var iconName: String {
        challenge.outcome == .completed ? "trophy.fill" : "arrow.clockwise"
    }

    private var iconColor: Color {
        challenge.outcome == .completed ? .orange : .mint
    }
}

private struct AppBackground: View {
    var body: some View {
        LinearGradient(
            colors: [
                Color(red: 0.03, green: 0.05, blue: 0.06),
                Color(red: 0.08, green: 0.10, blue: 0.11),
                Color(red: 0.02, green: 0.04, blue: 0.05)
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
