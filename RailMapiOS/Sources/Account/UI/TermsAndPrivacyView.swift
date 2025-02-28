//
//  TermsAndPrivacyView.swift
//  RailMapiOS
//
//  Created by Jérémie Patot on 28/02/2025.
//


import SwiftUI

struct TermsAndPrivacyView: View {
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("CONDITIONS D'UTILISATION ET POLITIQUE DE CONFIDENTIALITÉ")
                        .font(.title)
                        .fontWeight(.bold)
                        .padding(.bottom, 10)
                    
                    Group {
                        Text("CONDITIONS D'UTILISATION")
                            .font(.headline)
                            .fontWeight(.bold)
                        
                        Text("1. Acceptation des conditions")
                            .fontWeight(.bold)
                        Text("En téléchargeant et en utilisant l'application RailMap pour iOS, vous acceptez d'être lié par les présentes conditions d'utilisation. Si vous n'acceptez pas ces conditions, veuillez ne pas utiliser notre application.")
                        
                        Text("2. Utilisation de l'application")
                            .fontWeight(.bold)
                        Text("RailMap est fournie pour votre usage personnel et non commercial. Vous vous engagez à ne pas modifier, copier, distribuer, transmettre, afficher, exécuter, reproduire, publier, concéder sous licence, créer des œuvres dérivées, transférer ou vendre des informations obtenues à partir de l'application.")
                        
                        Text("3. Propriété intellectuelle")
                            .fontWeight(.bold)
                        Text("Tous les droits de propriété intellectuelle relatifs à l'application RailMap et son contenu appartiennent à leurs propriétaires respectifs et sont protégés par les lois applicables.")
                        
                        Text("4. Limitation de responsabilité")
                            .fontWeight(.bold)
                        Text("L'application RailMap est fournie \"telle quelle\" sans garantie d'aucune sorte. Nous ne garantissons pas que l'application sera exempte d'erreurs ou disponible de façon ininterrompue.")
                    }
                    
                    Group {
                        Text("POLITIQUE DE CONFIDENTIALITÉ")
                            .font(.headline)
                            .fontWeight(.bold)
                            .padding(.top, 20)
                        
                        Text("1. Collecte des informations")
                            .fontWeight(.bold)
                        Text("Notre application RailMap ne collecte aucune information personnelle des utilisateurs. Nous ne stockons ni ne traitons aucune donnée utilisateur sur nos serveurs backend.")
                        
                        Text("2. Données de localisation")
                            .fontWeight(.bold)
                        Text("Si vous autorisez l'accès à votre localisation, ces données sont uniquement utilisées localement sur votre appareil pour améliorer votre expérience de navigation et ne sont jamais transmises à nos serveurs.")
                        
                        Text("3. Informations sur l'appareil")
                            .fontWeight(.bold)
                        Text("Certaines informations techniques non personnelles (comme le modèle d'appareil et la version iOS) peuvent être collectées automatiquement pour assurer la compatibilité de l'application, mais ces données ne sont pas associées à votre identité.")
                        
                        Text("4. Sécurité")
                            .fontWeight(.bold)
                        Text("Bien que nous ne collections aucune donnée personnelle, nous prenons la sécurité de notre application au sérieux et mettons en œuvre des mesures appropriées pour protéger votre expérience utilisateur.")
                        
                        Text("5. Modifications de la politique")
                            .fontWeight(.bold)
                        Text("Nous nous réservons le droit de modifier cette politique de confidentialité à tout moment. Les modifications seront publiées dans l'application et prendront effet immédiatement.")
                        
                        Text("6. Contact")
                            .fontWeight(.bold)
                        Text("Pour toute question concernant cette politique de confidentialité, veuillez nous contacter à l'adresse suivante: contact@railmap-app.com")
                    }
                    
                    Text("Dernière mise à jour: 28 février 2025")
                        .italic()
                        .padding(.top, 20)
                }
                .padding()
            }
            .navigationBarTitle("Mentions légales", displayMode: .inline)
            .navigationBarItems(trailing: Button("Fermer") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}

struct TermsAndPrivacyView_Previews: PreviewProvider {
    static var previews: some View {
        TermsAndPrivacyView()
    }
}
