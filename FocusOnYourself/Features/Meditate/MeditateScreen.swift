import SwiftUI

struct MeditateScreen: View {
    @State private var viewModel = MeditateViewModel()
    @State private var selectedSession: MeditationSession?
    @State private var showingPaywall = false

    var body: some View {
        ZStack {
            Color.foyBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                headerRow

                CategoryFilterChipsView(viewModel: viewModel)
                    .padding(.bottom, Spacing.sm)

                ScrollView {
                    LazyVStack(spacing: Spacing.sm) {
                        ForEach(viewModel.filteredSessions) { session in
                            Button {
                                handleSessionTap(session)
                            } label: {
                                SessionCardView(session: session, isPro: viewModel.isPro)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, Spacing.screenHorizontal)
                    .padding(.top, Spacing.md)
                    .padding(.bottom, Spacing.screenBottom)
                }
                .scrollIndicators(.hidden)
            }
        }
        .fullScreenCover(item: $selectedSession) { session in
            MeditationPlayerView(session: session)
        }
        .sheet(isPresented: $showingPaywall) {
            PaywallScreen()
        }
    }

    private var headerRow: some View {
        HStack {
            Text("Meditate")
                .font(.foyNavTitle)
                .foregroundStyle(Color.foyForeground)
            Spacer()
        }
        .padding(.horizontal, Spacing.screenHorizontal)
        .padding(.top, Spacing.lg)
        .padding(.bottom, Spacing.md)
    }

    private func handleSessionTap(_ session: MeditationSession) {
        if session.isPro && !viewModel.isPro {
            showingPaywall = true
        } else {
            selectedSession = session
        }
    }
}
