import SwiftUI
import FoundationModels

// MARK: - Mode

enum MessageMode: String, CaseIterable {
    case simple   = "Simple"
    case romantic = "Romantic"
    case haiku    = "Haiku"
    case limerick = "Limerick"
}

// MARK: - BirthdayMessageView

struct BirthdayMessageView: View {
    let friend: Friend

    @State private var mode: MessageMode = .simple
    @State private var message: String = ""
    @State private var isGenerating = false
    @State private var showCopied = false
    @Environment(\.dismiss) private var dismiss

    private var modelAvailable: Bool {
        if #available(iOS 26, *) {
            return SystemLanguageModel.default.isAvailable
        }
        return false
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()

                VStack(alignment: .leading, spacing: 0) {
                    subtitle
                        .padding(.horizontal, 20)
                        .padding(.top, 4)
                        .padding(.bottom, 16)

                    modeSelector
                        .padding(.horizontal, 20)
                        .padding(.bottom, 16)

                    messageArea
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)

                        actionBar
                        .padding(.horizontal, 20)
                        .padding(.bottom, 28)
                }

                // Copy toast
                if showCopied {
                    VStack {
                        Spacer()
                        Text("Message copied to clipboard")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(AppTheme.primary.opacity(0.85))
                            .clipShape(Capsule())
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                            .padding(.bottom, 80)
                    }
                }
            }
            .navigationTitle(friend.fullName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(AppTheme.accent)
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .scrollDismissesKeyboard(.interactively)
        .onAppear {
            message = simpleMessage
        }
    }

    // MARK: - Sub-views

    private var subtitle: some View {
        HStack(spacing: 4) {
            if let str = friend.birthdayString {
                Text(str)
            }
            if let sign = friend.zodiacSign {
                Text("·")
                Text(sign)
            }
        }
        .font(.system(size: 13))
        .foregroundColor(AppTheme.secondary)
    }

    private var modeSelector: some View {
        HStack(spacing: 8) {
            ForEach(MessageMode.allCases, id: \.self) { m in
                if m == .simple || modelAvailable {
                    PillButton(title: m.rawValue, isSelected: mode == m) {
                        selectMode(m)
                    }
                    .disabled(isGenerating)
                }
            }
            Spacer()
            // Always rendered so layout never shifts; invisible when idle
            ProgressView()
                .tint(AppTheme.accent)
                .scaleEffect(0.85)
                .opacity(isGenerating ? 1 : 0)
                .animation(.easeInOut(duration: 0.2), value: isGenerating)
        }
    }

    private var messageArea: some View {
        TextEditor(text: $message)
            .font(.system(size: 15, weight: .light))
            .foregroundColor(isGenerating ? AppTheme.primary.opacity(0.3) : AppTheme.primary)
            .lineSpacing(5)
            .scrollContentBackground(.hidden)
            .padding(12)
            .background(AppTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .animation(.easeInOut(duration: 0.2), value: isGenerating)
            .disabled(isGenerating)
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    }
                    .foregroundColor(AppTheme.accent)
                }
            }
    }

    private var actionBar: some View {
        HStack(spacing: 32) {
            Spacer()

            Button {
                UIPasteboard.general.string = message
                withAnimation(.easeInOut(duration: 0.2)) { showCopied = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    withAnimation(.easeInOut(duration: 0.2)) { showCopied = false }
                }
            } label: {
                Image(systemName: "doc.on.doc")
                    .font(.system(size: 22))
                    .foregroundColor(AppTheme.accent)
            }
            .disabled(isGenerating || message.isEmpty)

            if let phone = friend.primaryPhone {
                Button {
                    sendSMS(to: phone.number, body: message)
                } label: {
                    Image(systemName: "message")
                        .font(.system(size: 22))
                        .foregroundColor(AppTheme.accent)
                }
                .disabled(isGenerating)
            }

            if let email = friend.primaryEmail {
                Button {
                    sendEmail(to: email.email, body: message)
                } label: {
                    Image(systemName: "envelope")
                        .font(.system(size: 22))
                        .foregroundColor(AppTheme.accent)
                }
                .disabled(isGenerating)
            }

            Spacer()
        }
    }

    // MARK: - Logic

    private func selectMode(_ newMode: MessageMode) {
        mode = newMode

        if newMode == .simple {
            message = simpleMessage
            return
        }

        Task { await generate(for: newMode) }
    }

    private func generate(for targetMode: MessageMode) async {
        isGenerating = true
        defer { isGenerating = false }

        if #available(iOS 26, *) {
            await generateWithFoundationModels(for: targetMode)
        } else {
            message = freshFallback(for: targetMode)
        }
    }

    /// Picks a fallback variant that differs from the currently displayed message.
    private func freshFallback(for targetMode: MessageMode) -> String {
        let current = message
        var candidate = localFallback(for: targetMode)
        // Retry up to 5 times to avoid repeating the same variant
        for _ in 0..<5 where candidate == current {
            candidate = localFallback(for: targetMode)
        }
        return candidate
    }

    @available(iOS 26, *)
    private func generateWithFoundationModels(for targetMode: MessageMode) async {
        do {
            let session = LanguageModelSession()
            let response = try await session.respond(to: prompt(for: targetMode))
            message = response.content
        } catch {
            message = freshFallback(for: targetMode)
        }
    }

    // MARK: - Helpers

    private var simpleMessage: String {
        let cake = String(Unicode.Scalar(0x1F382)!) // birthday cake emoji
        let name = friend.firstName
        if let age = friend.turningAge {
            return "Happy birthday, \(name)! \(cake) Wishing you a wonderful \(age)th — may your day be filled with joy and celebration."
        }
        return "Happy birthday, \(name)! \(cake) Wishing you a wonderful day filled with joy, laughter, and everything you love."
    }

    private func prompt(for targetMode: MessageMode) -> String {
        let name = friend.firstName
        let month: String = {
            guard let b = friend.birthday else { return "this month" }
            let f = DateFormatter(); f.dateFormat = "MMMM"
            return f.string(from: b)
        }()
        let sign = friend.zodiacSign ?? "a wonderful person"

        switch targetMode {
        case .simple:
            return ""
        case .romantic:
            return "Write a warm, heartfelt birthday message for \(name), who is a \(sign). Make it poetic and sincere, 2–3 sentences. End with a single relevant emoji. Reply with only the message, no preamble."
        case .haiku:
            return "Write a birthday haiku for \(name), a \(sign) born in \(month). Stick strictly to 5-7-5 syllables. Reply with only the haiku, no preamble."
        case .limerick:
            return "Write a fun birthday limerick for \(name), a \(sign) born in \(month). Make it warm and celebratory. Reply with only the limerick, no preamble."
        }
    }

    private func localFallback(for targetMode: MessageMode) -> String {
        let name = friend.firstName
        let sign = friend.zodiacSign ?? "star"

        switch targetMode {
        case .simple:
            return simpleMessage

        case .romantic:
            let sparkles = String(Unicode.Scalar(0x2728)!)  // sparkles
            let star     = String(Unicode.Scalar(0x1F31F)!) // glowing star
            let swirl    = String(Unicode.Scalar(0x1F4AB)!) // dizzy/swirl
            let blossom  = String(Unicode.Scalar(0x1F338)!) // cherry blossom
            let variants = [
                "To \(name) — may this birthday bring you all the magic your beautiful heart deserves. \(sparkles)",
                "Happy birthday, \(name). May today remind you how deeply you are cherished and how brightly you shine. \(star)",
                "Wishing you a birthday as beautiful and rare as you are, \(name). Every year with you in it is a gift. \(swirl)",
                "To the wonderful \(name) — may this day be filled with all the love and wonder you so freely give to others. \(blossom)",
            ]
            return variants.randomElement()!

        case .haiku:
            let variants = [
                "Birthday dawn arrives\n\(name) shines bright like \(sign)\nAnother year glows",
                "Candles flicker soft\n\(name) laughs and the light grows\nJoy fills every room",
                "One more year of you\n\(sign) wisdom, \(name)'s grace\nThe world is richer",
                "Spring of another\nyear blooms gently around \(name)\nWe celebrate you",
            ]
            return variants.randomElement()!

        case .limerick:
            let variants = [
                "There once was a friend named \(name),\nWhose birthday just can't be mundane,\n  With cake, song, and cheer,\nThe best of the year,\nHappy birthday again and again!",
                "A wonderful person named \(name)\nWas born under \(sign)'s bright domain,\n  May your day be grand,\nExactly as planned,\nAnd the cake leave a sweet little stain!",
                "Here's to \(name) on this fine day,\nWho brightens the world in their way,\n  With a \(sign) heart,\nA true work of art,\nHappy birthday — hip hip hip hooray!",
                "The stars smiled the day \(name) arrived,\nA \(sign) soul perfectly contrived,\n  May your birthday be bright,\nFrom morning to night,\nAnd may all of your wishes be prized!",
            ]
            return variants.randomElement()!
        }
    }

    private func sendSMS(to number: String, body: String) {
        let clean = number.filter(\.isNumber)
        let encoded = body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        if let url = URL(string: "sms:\(clean)&body=\(encoded)") {
            UIApplication.shared.open(url)
        }
    }

    private func sendEmail(to address: String, body: String) {
        let encoded = body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        if let url = URL(string: "mailto:\(address)?body=\(encoded)") {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - PillButton

struct PillButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .lineLimit(1)
                .fixedSize()
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(isSelected ? AppTheme.accent : AppTheme.surface)
                .foregroundColor(isSelected ? .white : AppTheme.secondary)
                .clipShape(Capsule())
        }
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }
}
