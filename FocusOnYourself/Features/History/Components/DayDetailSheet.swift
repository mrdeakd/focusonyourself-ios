import SwiftUI

struct DayDetailSheet: View {
    let checkIn: CheckIn

    @Environment(\.dismiss) private var dismiss

    private var moodLevel: Int {
        switch checkIn.mood {
        case .rough: return 1
        case .low:   return 2
        case .okay:  return 3
        case .good:  return 4
        case .great: return 5
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            SheetDragHandle()
            DayDetailHeaderSection(checkIn: checkIn)
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    DayMoodSection(checkIn: checkIn, moodLevel: moodLevel)
                    DayJournalSection(checkIn: checkIn)
                }
            }
            .scrollIndicators(.hidden)
            DayDoneButton {
                dismiss()
            }
            .padding(.bottom, Spacing.xl)
        }
        .padding(.horizontal, Spacing.md)
        .background(Color.foyBackground)
        .presentationDetents([.fraction(0.55)])
        .presentationDragIndicator(.hidden)
        .presentationBackground(Color.foyBackground)
    }
}

// MARK: - DayDetailHeaderSection

struct DayDetailHeaderSection: View {
    let checkIn: CheckIn

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(checkIn.date.homeScreenFormatted)
                .font(.foyCaption)
                .foregroundStyle(Color.foyForegroundSecondary)
            Text("Your Day")
                .font(.foyNavTitle)
                .foregroundStyle(Color.foyForeground)
        }
        .padding(.vertical, Spacing.md)
    }
}

// MARK: - DayMoodSection

struct DayMoodSection: View {
    let checkIn: CheckIn
    let moodLevel: Int

    private let emojiSize: CGFloat = 52
    private let moodCardPadding: CGFloat = 20

    var body: some View {
        VStack(spacing: Spacing.xs) {
            Image(checkIn.mood.imageName)
                .renderingMode(.template)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: emojiSize, height: emojiSize)
                .foregroundStyle(.primary)
            Text(checkIn.mood.displayName)
                .font(.foyHeadline)
                .foregroundStyle(Color.foyNavy)
            DayMoodDotsRow(moodLevel: moodLevel)
        }
        .frame(maxWidth: .infinity)
        .padding(moodCardPadding)
        .foyCardStyle(borderColor: .foyNavy)
        .padding(Spacing.xxs)
    }
}

// MARK: - DayMoodDotsRow

struct DayMoodDotsRow: View {
    let moodLevel: Int

    private let dotSize: CGFloat = 10
    private let dotSpacing: CGFloat = 8
    private let emptyDotFill = Color.foyDetailDotFill
    private let emptyDotStroke = Color.foyDetailDotStroke

    var body: some View {
        HStack(spacing: dotSpacing) {
            ForEach(1...5, id: \.self) { index in
                if index <= moodLevel {
                    Circle()
                        .fill(Color.foyNavy)
                        .frame(width: dotSize, height: dotSize)
                } else {
                    Circle()
                        .fill(emptyDotFill)
                        .frame(width: dotSize, height: dotSize)
                        .overlay {
                            Circle().stroke(emptyDotStroke, lineWidth: 1.5)
                        }
                }
            }
        }
    }
}

// MARK: - DayJournalSection

struct DayJournalSection: View {
    let checkIn: CheckIn

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            SectionLabel("JOURNAL")
            Text(checkIn.feelingsDescription ?? "No notes for this day.")
                .font(.foyBody)
                .foregroundStyle(Color.foyForeground)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

// MARK: - DayDoneButton

struct DayDoneButton: View {
    let onDismiss: () -> Void

    var body: some View {
        Button("Done") {
            onDismiss()
        }
        .buttonStyle(FoyPrimaryButtonStyle())
        .padding(.top, Spacing.md)
    }
}
