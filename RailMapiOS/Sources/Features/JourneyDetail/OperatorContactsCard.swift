//
//  OperatorContactsCard.swift
//  RailMapiOS
//
//  Always-visible card at the bottom of JourneyDetailView (Flighty-style)
//  showing how to reach the operator's customer service: phone, email, X
//  handle, website. Each row taps to open the corresponding system handler.
//

import SwiftUI

struct OperatorContactsCard: View {
    let contact: OperatorContact
    @Environment(\.openURL) private var openURL

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Contact \(contact.displayName)")
                .font(.footnote)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
                .padding(.leading, 6)

            VStack(spacing: 0) {
                if let phone = contact.phone {
                    contactRow(
                        icon: "phone.fill",
                        color: .green,
                        label: "Phone",
                        value: phone,
                        url: URL(string: "tel:\(phone.filter(\.isNumber))")
                    )
                }

                if contact.phone != nil, contact.email != nil {
                    rowDivider
                }

                if let email = contact.email {
                    contactRow(
                        icon: "envelope.fill",
                        color: .blue,
                        label: "Email",
                        value: email,
                        url: URL(string: "mailto:\(email)")
                    )
                }

                if (contact.phone != nil || contact.email != nil) && contact.twitterHandle != nil {
                    rowDivider
                }

                if let handle = contact.twitterHandle {
                    contactRow(
                        icon: "bubble.left.and.bubble.right.fill",
                        color: .purple,
                        label: "X (Twitter)",
                        value: "@\(handle)",
                        url: URL(string: "https://x.com/\(handle)")
                    )
                }

                if (contact.phone != nil || contact.email != nil || contact.twitterHandle != nil) && contact.websiteURL != nil {
                    rowDivider
                }

                if let website = contact.websiteURL {
                    contactRow(
                        icon: "globe",
                        color: .indigo,
                        label: "Website",
                        value: website.host ?? website.absoluteString,
                        url: website
                    )
                }
            }
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18))
        }
    }

    // MARK: - Row

    private func contactRow(icon: String, color: Color, label: LocalizedStringResource, value: String, url: URL?) -> some View {
        Button {
            if let url { openURL(url) }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(color)
                    .frame(width: 30, height: 30)
                    .background(color.opacity(0.15), in: RoundedRectangle(cornerRadius: 8))
                Text(label)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                Spacer(minLength: 8)
                Text(verbatim: value)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                Image(systemName: "arrow.up.forward.app")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 11)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var rowDivider: some View {
        Divider()
            .padding(.leading, 56)
            .opacity(0.5)
    }
}
