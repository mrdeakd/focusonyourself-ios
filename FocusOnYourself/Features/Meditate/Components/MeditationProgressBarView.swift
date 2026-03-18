import SwiftUI

struct MeditationProgressBarView: View {
    let stepCount: Int
    let currentStepIndex: Int

    var body: some View {
        HStack(spacing: Spacing.xxxs) {
            ForEach(0..<stepCount, id: \.self) { index in
                Capsule()
                    .fill(index <= currentStepIndex ? Color.foyOnPrimary : Color.foyOnPrimary.opacity(0.25))
                    .frame(height: 4)
            }
        }
    }
}
