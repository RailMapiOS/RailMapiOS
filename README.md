# RailMapiOS  
![Platform](https://img.shields.io/badge/platform-iOS-blue)
![Swift](https://img.shields.io/badge/Swift-6.0-orange?logo=swift)
![SwiftUI](https://img.shields.io/badge/SwiftUI-Compatible-blue)
![GitHub commits](https://img.shields.io/github/commit-activity/m/RailMapiOS/RailMapiOS)
![SwiftLint](https://github.com/RailMapiOS/RailMapiOS/actions/workflows/SwiftLintCheck.yml/badge.svg)
![CI](https://github.com/RailMapiOS/RailMapiOS/actions/workflows/AllPR-Build-Tests.yml/badge.svg)  
![GitHub release](https://img.shields.io/github/v/release/utilisateur/RailMapiOS)
![GitHub](https://img.shields.io/github/license/RailMapiOS/RailMapiOS)


## 🚄 Description  
RailMapiOS est une application iOS conçue pour offrir une nouvelle façon de suivre les voyages en train. Développée entièrement en **SwiftUI**, cette application permet aux utilisateurs de voyager sans stress, de prévoir les **retards** et d’obtenir des **mises à jour instantanées** sur leurs trajets ferroviaires.  

## ✨ Fonctionnalités  
- 🗺️ **Visualisation des itinéraires** sur une carte interactive  
- 🎫 **Gestion des billets et des réservations**  
- 📱 **Interface utilisateur** intuitive et moderne  

## 🖼️ Captures d’écran  
<img src="https://github.com/user-attachments/assets/0319b238-a39e-4b41-888b-4335378b11c6" width="300">
<img src="https://github.com/user-attachments/assets/9cf429e0-73b3-43f9-8d42-2fd2f0c153e4" width="300">
<img src="https://github.com/user-attachments/assets/a48213aa-006f-4710-bd1e-cce45007d7ef" width="300">
<img src="https://github.com/user-attachments/assets/54764255-ef45-4c90-a16e-d52b1f4afefa" width="300">
<img src="https://github.com/user-attachments/assets/6a75a4bb-12ec-4c0c-a98f-d312f6c4071c" width="300">


## 🛠️ Technologies utilisées  
- **SwiftUI** pour l’interface utilisateur  
- **CoreData** pour la persistance des données  
- **MapKit** pour l’affichage des cartes  
- **CloudKit** pour la synchronisation des données  
- **Vapor** pour le backend  

## 🏗️ Architecture du projet  
L’application suit une architecture **MVVM (Model-View-ViewModel)** pour une séparation claire des responsabilités :  
- 🏛️ **Models** : Définitions des données et logique métier  
- 🎨 **Views** : Interfaces utilisateur en SwiftUI  
- 🧠 **ViewModels** : Logique de présentation et liaison de données  
- 🔌 **Services** : Couche d’accès aux données et API  

## 🚀 Roadmap  
- 📍 **Suivi en temps réel** des trajets ferroviaires
- 🚦 **Notifications** de retards et de changements de voie  (GTFS-R)
- 🔗 Intégration avec d’autres services de transport  
- ⏳ Amélioration des **prédictions de retard**  
- 🌍 Support **multilingue**  
- 📱 Version **iPad optimisée**  
- 🏠 Widgets pour l’écran d’accueil
- 💡 Refonte de l’**architecture en MVI**
-  🖥️ Version macOS

## 📜 Licence  
Ce projet est sous licence **Apache 2.0**. Voir le fichier [`LICENSE`](LICENSE) pour plus de détails.  

---

🚆 **RailMapiOS** - Une nouvelle façon de voyager en train !  
