//
//  JourneyHeaderView.swift
//  RailMapiOS
//
//  Created by Jérémie Patot on 18/09/2024.
//


import SwiftUI

struct JourneyHeaderView: View {
    let company: String?
    let headsign: String?
    let size: CGSize?
    
    public init(company: String? = nil, headsign: String? = nil, size: CGSize? = nil) {
        self.company = company
        self.headsign = headsign
        self.size = size
    }
    
    var body: some View {
        HStack {
            CompanyLogo(company, size: size)
            Spacer()
            JourneyInfoView(headsign: headsign, company: company)
        }
        .padding(.horizontal)
    }
}

struct JourneyInfoView: View {
    let headsign: String?
    let company: String?
    
    var body: some View {
        VStack(alignment: .trailing) {
            if let headsign = headsign, let company = company {
                Text(headsign)
                    .font(.title3)
                Text(company)
                    .font(.subheadline)
            }
        }
    }
}
