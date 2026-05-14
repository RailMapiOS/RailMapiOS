//
//  RefundFlowView.swift
//  RailMapiOS
//
//  Refund-claim WebView with a paged carousel of copyable info chips.
//  Layout:
//    ┌──────────────────────────────────┐
//    │ Toolbar: Close · OperatorName    │
//    ├──────────────────────────────────┤
//    │ Chips carousel (paged TabView)   │  ← top, ~110pt tall
//    │ • • ●  4/6                       │
//    ├──────────────────────────────────┤
//    │                                  │
//    │ WKWebView (operator claim form)  │  ← fills the rest
//    │                                  │
//    └──────────────────────────────────┘
//

import ComposableArchitecture
import SwiftUI
import WebKit

struct RefundFlowView: View {
    @Bindable var store: StoreOf<RefundFlowFeature>

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if store.requiresLogin {
                    loginHint
                }
                chipsCarousel
                Divider()
                webView
            }
            .navigationTitle(Text(verbatim: store.operatorName))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { store.send(.dismissTapped) }
                }
            }
        }
    }

    // MARK: - Login hint banner

    private var loginHint: some View {
        HStack(spacing: 8) {
            Image(systemName: "person.badge.key.fill")
                .foregroundStyle(.orange)
            Text("Sign in to your operator account first — your session will persist for next time.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.orange.opacity(0.1))
    }

    // MARK: - Chips carousel

    private var chipsCarousel: some View {
        VStack(spacing: 6) {
            TabView(selection: $store.selectedChipIndex) {
                ForEach(Array(chips.enumerated()), id: \.offset) { idx, chip in
                    chipCard(chip)
                        .tag(idx)
                        .padding(.horizontal, 16)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height: 86)

            // Page indicator + step counter (tighter than the default dots)
            HStack(spacing: 4) {
                ForEach(0..<chips.count, id: \.self) { i in
                    Circle()
                        .fill(i == store.selectedChipIndex ? Color.accentColor : Color.secondary.opacity(0.3))
                        .frame(width: 6, height: 6)
                }
                Spacer(minLength: 8)
                Text("\(store.selectedChipIndex + 1) / \(chips.count)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
        }
        .background(.regularMaterial)
    }

    private func chipCard(_ chip: ChipDescriptor) -> some View {
        Button {
            UIPasteboard.general.string = chip.value
            store.send(.chipTapped(chip.id, value: chip.value))
        } label: {
            HStack(spacing: 12) {
                Image(systemName: chip.icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(chip.color)
                    .frame(width: 32, height: 32)
                    .background(chip.color.opacity(0.15), in: RoundedRectangle(cornerRadius: 8))

                VStack(alignment: .leading, spacing: 2) {
                    Text(chip.label)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(verbatim: chip.value)
                        .font(.headline)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }

                Spacer(minLength: 8)

                Image(systemName: store.lastCopiedChipID == chip.id ? "checkmark.circle.fill" : "doc.on.doc")
                    .font(.system(size: 18))
                    .foregroundStyle(store.lastCopiedChipID == chip.id ? .green : .secondary)
                    .symbolEffect(.bounce, value: store.lastCopiedChipID == chip.id)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }

    // MARK: - WebView

    private var webView: some View {
        WebViewContainer(url: store.claimURL)
            .ignoresSafeArea(edges: .bottom)
    }

    // MARK: - Chip data

    private struct ChipDescriptor: Identifiable {
        let id: RefundFlowFeature.ChipID
        let label: LocalizedStringResource
        let value: String
        let icon: String
        let color: Color
    }

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .long
        f.timeStyle = .short
        return f
    }()

    private var chips: [ChipDescriptor] {
        [
            ChipDescriptor(
                id: .bookingReference,
                label: "Booking reference",
                value: store.bookingReference ?? "—",
                icon: "ticket.fill",
                color: .pink
            ),
            ChipDescriptor(
                id: .trainNumber,
                label: "Train number",
                value: store.trainNumber,
                icon: "number",
                color: .indigo
            ),
            ChipDescriptor(
                id: .journeyDate,
                label: "Date",
                value: Self.dateFormatter.string(from: store.journeyDate),
                icon: "calendar",
                color: .orange
            ),
            ChipDescriptor(
                id: .departure,
                label: "Departure",
                value: store.departureLabel,
                icon: "tram.tunnel.fill",
                color: .blue
            ),
            ChipDescriptor(
                id: .arrival,
                label: "Arrival",
                value: store.arrivalLabel,
                icon: "mappin.and.ellipse",
                color: .green
            ),
            ChipDescriptor(
                id: .delayMinutes,
                label: "Delay",
                value: "\(store.delayMinutes) min",
                icon: "clock.badge.exclamationmark.fill",
                color: .red
            ),
        ]
    }
}

// MARK: - WKWebView UIViewRepresentable

private struct WebViewContainer: UIViewRepresentable {
    typealias UIViewType = WKWebView

    let url: URL

    func makeUIView(context: UIViewRepresentableContext<WebViewContainer>) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.websiteDataStore = .default()  // persists cookies across launches
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.allowsBackForwardNavigationGestures = true
        webView.load(URLRequest(url: url))
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: UIViewRepresentableContext<WebViewContainer>) {
        // No reactive updates — the URL is set once when the view is created.
        // Future: inject JS bridge here to sync chip carousel with focused field.
    }
}
