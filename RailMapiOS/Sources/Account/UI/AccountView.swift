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
                                .frame(height: 34)
                                .clipShape(.circle)
                        } else {
                            Image(systemName: "person.crop.circle.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(height: 34)
                                .foregroundStyle(.green)
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
                    
                    
                    Button {
                        print("setting")
                    } label: {
                        RoundedRectangle(cornerRadius: 100)
                            .stroke()
                            .frame(width: 100, height: 30)
                            .overlay(
                                HStack {
                                    Image(systemName: "gear")
                                        .font(.caption)
                                    Text("Settings")
                                        .font(.caption)
                                }
                                    .foregroundStyle(.black)
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

//struct SheetPreview: View {
//    @State private var isPresented = true
//
//    var body: some View {
//        Text("Main Content")
//            .sheet(isPresented: $isPresented) {
//                AccountView(user: User(userId: "test123", firstName: "Jeremie", lastName: "Patot", email: "exemple@exemple.com", profileImage: nil))
//                    .padding(.top)
//                    .presentationDetents([.fraction(0.3), .medium, .large])
//                    .presentationBackgroundInteraction(.enabled)
//                    .interactiveDismissDisabled()
//                    .ignoresSafeArea()
//            }
//           
//    }
//}
//
//
//#Preview {
//    SheetPreview()
//}
