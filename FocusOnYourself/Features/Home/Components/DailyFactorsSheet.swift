import SwiftUI

struct DailyFactorsSheet: View {
    @Bindable var viewModel: HomeViewModel

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color.foyBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                SheetDragHandle()
                SheetHeader(title: "Today's context") { dismiss() }

                VStack(alignment: .leading, spacing: Spacing.lg) {
                    Text("What shaped your day?")
                        .font(.foyCaption)
                        .foregroundStyle(Color.foyForegroundSecondary)

                    FactorSlidersView(viewModel: viewModel)
                }
                .padding(.top, Spacing.lg)
                .padding(.horizontal, Spacing.screenHorizontal)
                .frame(maxWidth: .infinity, alignment: .leading)

                Spacer()

                Button("Save") {
                    viewModel.saveContext()
                    dismiss()
                }
                .buttonStyle(FoyPrimaryButtonStyle())
                .padding(.top, Spacing.sm)
                .padding(.horizontal, Spacing.screenHorizontal)
                .padding(.bottom, Spacing.xxl)
            }
        }
        .presentationDetents([.fraction(0.65)])
        .presentationDragIndicator(.hidden)
        .presentationBackground(Color.foyBackground)
        .onAppear {
            viewModel.loadFactorsFromToday()
        }
    }
}
