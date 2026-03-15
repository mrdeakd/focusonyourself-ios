import SwiftUI

private let emojiSize: CGFloat = 52
private let dragHandleWidth: CGFloat = 36
private let dragHandleHeight: CGFloat = 4
private let dragHandleCornerRadius: CGFloat = 2
private let moodCardPadding: CGFloat = 20
private let dotSize: CGFloat = 10
private let dotSpacing: CGFloat = 8
private let pencilIconSize: CGFloat = 14
private let pencilIconColor = Color(red: 0.722, green: 0.659, blue: 0.541)
private let emptyDotFill = Color(red: 0.898, green: 0.894, blue: 0.882)
private let emptyDotStroke = Color(red: 0.784, green: 0.780, blue: 0.769)

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
            handleArea
            headerSection
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    sheetDivider
                    moodSection
                    sheetDivider
                    journalSection
                    sheetDivider
                }
            }
            doneButton
                .padding(.bottom, Spacing.xl)
        }
        .padding(.horizontal, Spacing.md)
        .padding(.top, Spacing.xs)
        .background(Color.foyBackground)
        .presentationDetents([.fraction(0.65)])
        .presentationDragIndicator(.hidden)
        .presentationBackground(Color.foyBackground)
    }

    // MARK: - Subviews

    private var handleArea: some View {
        HStack {
            Spacer()
            RoundedRectangle(cornerRadius: dragHandleCornerRadius)
                .fill(Color.foyButtonDisabled)
                .frame(width: dragHandleWidth, height: dragHandleHeight)
            Spacer()
        }
        .padding(.top, 14)
        .padding(.bottom, 6)
    }

    private var headerSection: some View {
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

    private var moodSection: some View {
        VStack(spacing: Spacing.xs) {
            Text(checkIn.mood.emoji)
                .font(.system(size: emojiSize))
            Text(checkIn.mood.displayName)
                .font(.foyHeadline)
                .foregroundStyle(Color.foyNavy)
            moodDotsRow
        }
        .frame(maxWidth: .infinity)
        .padding(moodCardPadding)
        .background(Color.foyMoodBackground)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.input))
        .shadow(color: Color.black.opacity(0.1), radius: 6, x: 0, y: 2)
        .padding(.vertical, Spacing.md)
    }

    private var moodDotsRow: some View {
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
                        .overlay(
                            Circle().stroke(emptyDotStroke, lineWidth: 1.5)
                        )
                }
            }
        }
    }

    private var journalSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Text("JOURNAL")
                    .font(.foySectionLabel)
                    .foregroundStyle(Color.foyPlaceholder)
                Spacer()
            }
            Text(checkIn.feelingsDescription ?? "No notes for this day.")
                .font(.foyBody)
                .foregroundStyle(Color.foyForeground)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(Spacing.md)
                .background(Color.foyBackground)
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.categoryTag))
                .overlay(
                    RoundedRectangle(cornerRadius: CornerRadius.categoryTag)
                        .stroke(Color.foyBorder, lineWidth: 1)
                )
        }
        .padding(.vertical, Spacing.md)
    }

    private var sheetDivider: some View {
        Divider()
            .overlay(Color.foyBorder)
    }

    private var doneButton: some View {
        Button {
            dismiss()
        } label: {
            Text("Done")
                .font(.foyButtonLabel)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.buttonVertical)
                .background(Color.foyNavy)
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.pill))
        }
        .padding(.top, Spacing.md)
    }
}
