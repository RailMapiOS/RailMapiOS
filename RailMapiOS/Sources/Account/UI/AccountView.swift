//
//  AccountView.swift
//  RailMapiOS
//
//  Created by Jérémie Patot on 15/02/2025.
//

import SwiftUI

struct AccountView: View {
    @ObservedObject var userStorage: UserStorage
    var body: some View {
        VStack {
            
            if let user = userStorage.currentUser  {
                VStack (alignment: .leading) {
                    //MARK: Header
                    HStack(alignment: .center) {
                        if let data = user.profileImage ,
                           let uiImage = UIImage(data: data) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFit()
                                .frame(height: 40)
                                .clipShape(.circle)
                                .padding(.horizontal, 10)
                        } else {
                            Image(systemName: "person.crop.circle.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(height: 40)
                                .foregroundStyle(.green)
                                .padding(.horizontal, 10)
                        }
                        
                        VStack (alignment: .leading) {
                            Text("\(user.firstName) \(user.lastName)")
                                .fontWeight(.medium)
                                .font(.title2)
                            Text("My Train log")
                                .font(.caption)
                                .foregroundStyle(.gray)
                        }
                        Spacer()
                    }
                    .padding(.top)
                    
                    
                    Button {
                        print("setting")
                    } label: {
                        RoundedRectangle(cornerRadius: 100)
                            .stroke()
                            .frame(width: 90, height: 25)
                            .overlay(
                                HStack {
                                    Image(systemName: "gear")
                                        .font(.caption)
                                    Text("Settings")
                                        .font(.caption)
                                }
                                    .foregroundStyle(.gray)
                            )
                            .foregroundStyle(.gray)
                        
                    }
                    
                }
                .padding(.horizontal)
                
                
                Divider()
                ScrollView {
                    TrainTravelSummaryCard(numberOfTrips: 42, totalDistance: 1245.67, timeSpentOnTrains: "2j 4h 32m", numberOfStationsVisited: 68)
                    //.preferredColorScheme(.dark)
                }
            }
        }
    }
}
