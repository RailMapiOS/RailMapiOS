//
//  JourneyStatusBadge.swift
//  RailMapiOS
//
//  Created by Jérémie Patot on 07/03/2026.
//

import SwiftUI

struct JourneyStatusBadge: View {
    let status: JourneyStatus

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)
            Text(status.label)
                .font(.caption2)
                .fontWeight(.medium)
        }
        .foregroundStyle(color)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.12), in: Capsule())
        .modifier(GlassInteractiveModifier())
    }

    private var color: Color {
        switch status {
        case .upcoming: return .blue
        case .inProgress: return .green
        case .completed: return .secondary
        case .delayed: return .orange
        case .cancelled: return .red
        }
    }
}

private struct GlassInteractiveModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content.glassEffect(.regular.interactive())
        } else {
            content
        }
    }
}

#Preview {
    VStack(spacing: 8) {
        JourneyStatusBadge(status: .upcoming)
        JourneyStatusBadge(status: .inProgress)
        JourneyStatusBadge(status: .completed)
        JourneyStatusBadge(status: .delayed)
        JourneyStatusBadge(status: .cancelled)
    }
}
