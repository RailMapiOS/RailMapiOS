//
//  Logger.swift
//  RailMapiOS
//
//  Created by Jérémie Patot on 14/03/2025.
//

import OSLog

/// Un système de journalisation unifié pour RailMapiOS
///
/// `LogManager` fournit une interface simple et cohérente pour journaliser des messages
/// avec différents niveaux de sévérité et de confidentialité.
///
/// ## Exemple d'utilisation
/// ```
/// // Journaliser un message d'information
/// LogManager.info("Application démarrée")
///
/// // Journaliser une erreur avec des données privées
/// LogManager.error("Échec de connexion pour l'utilisateur", privacy: .private)
///
/// // Journaliser un message de débogage avec une catégorie spécifique
/// LogManager.debug("Valeur calculée: 42", category: "calculations")
/// ```
struct LogManager {
    // MARK: - Propriétés privées
    
    /// Identifiant du sous-système pour la journalisation
    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.railmap.ios"
    
    // MARK: - Types internes
    
    /// Définit les niveaux de confidentialité pour les messages journalisés
    ///
    /// Ces niveaux correspondent aux options de confidentialité d'OSLog
    /// et permettent de contrôler comment les données sensibles sont traitées.
    enum Privacy {
        /// Données publiques visibles dans les journaux
        case `public`
        /// Données privées masquées dans les journaux publics
        case `private`
        /// Données sensibles fortement protégées
        case sensitive
        /// Confidentialité déterminée automatiquement
        case auto
        /// Adresse email (masquée automatiquement)
    }
    
    // MARK: - Méthodes privées
    
    /// Journalise un message avec le niveau et la confidentialité spécifiés
    ///
    /// - Parameters:
    ///   - level: Niveau de journalisation (debug, info, warning, error, fault)
    ///   - message: Message à journaliser
    ///   - category: Catégorie du message
    ///   - privacy: Niveau de confidentialité du message
    ///   - file: Fichier source (automatique)
    ///   - line: Numéro de ligne (automatique)
    ///   - function: Fonction appelante (automatique)
    ///   - emoji: Emoji préfixant le message pour une identification visuelle
    private static func log(
        level: OSLogType,
        message: String,
        category: String,
        file: String,
        line: Int,
        function: String
    ) {
        let logger = Logger(subsystem: subsystem, category: category)
        let fileInfo = "(\(file):\(line) - \(function))"
        let levelString = levelName(for: level)
        let formattedMessage: String
        switch level {
        case .debug:
            formattedMessage = "🔍 [\(levelString)] \(fileInfo) \(message)"
            logger.debug("\(formattedMessage, privacy: .auto)")
        case .info:
            formattedMessage = "ℹ️ [\(levelString)] \(fileInfo) \(message)"
                logger.info("\(formattedMessage, privacy: .auto)")
        case .error:
            formattedMessage = "🔥 [\(levelString)] \(fileInfo) \(message)"
                logger.error("\(formattedMessage, privacy: .auto)")
        case .fault:
            formattedMessage = "🚨 [\(levelString)] \(fileInfo) \(message)"
                logger.fault("\(formattedMessage, privacy: .auto)")
        default:
            formattedMessage = "⚠️ [\(levelString)] \(fileInfo) \(message)"
                logger.warning("\(formattedMessage, privacy: .auto)")
        }
    }
    
    private static func logPrivate(
        level: OSLogType,
        message: String,
        category: String,
        file: String,
        line: Int,
        function: String
    ) {
        let logger = Logger(subsystem: subsystem, category: category)
        let fileInfo = "(\(file):\(line) - \(function))"
        let levelString = levelName(for: level)
        let formattedMessage: String
        switch level {
        case .debug:
            formattedMessage = "🔍 [\(levelString)] \(fileInfo) \(message)"
            logger.debug("\(formattedMessage, privacy: .private)")
        case .info:
            formattedMessage = "ℹ️ [\(levelString)] \(fileInfo) \(message)"
            logger.info("\(formattedMessage, privacy: .private)")
        case .error:
            formattedMessage = "🔥 [\(levelString)] \(fileInfo) \(message)"
            logger.error("\(formattedMessage, privacy: .private)")
        case .fault:
            formattedMessage = "🚨 [\(levelString)] \(fileInfo) \(message)"
            logger.fault("\(formattedMessage, privacy: .private)")
        default:
            formattedMessage = "⚠️ [\(levelString)] \(fileInfo) \(message)"
            logger.warning("\(formattedMessage, privacy: .private)")
        }
    }
    
    private static func logSensitive(
        level: OSLogType,
        message: String,
        category: String,
        file: String,
        line: Int,
        function: String
    ) {
        let logger = Logger(subsystem: subsystem, category: category)
        let fileInfo = "(\(file):\(line) - \(function))"
        let levelString = levelName(for: level)
        let formattedMessage: String
        switch level {
        case .debug:
            formattedMessage = "🔍 [\(levelString)] \(fileInfo) \(message)"
            logger.debug("\(formattedMessage, privacy: .sensitive)")
        case .info:
            formattedMessage = "ℹ️ [\(levelString)] \(fileInfo) \(message)"
            logger.info("\(formattedMessage, privacy: .sensitive)")
        case .error:
            formattedMessage = "🔥 [\(levelString)] \(fileInfo) \(message)"
            logger.error("\(formattedMessage, privacy: .sensitive)")
        case .fault:
            formattedMessage = "🚨 [\(levelString)] \(fileInfo) \(message)"
            logger.fault("\(formattedMessage, privacy: .sensitive)")
        default:
            formattedMessage = "⚠️ [\(levelString)] \(fileInfo) \(message)"
            logger.warning("\(formattedMessage, privacy: .sensitive)")
        }
    }
    
    /// Retourne le nom du niveau de journalisation
    ///
    /// - Parameter level: Niveau de journalisation OSLogType
    /// - Returns: Nom du niveau sous forme de chaîne
    private static func levelName(for level: OSLogType) -> String {
        switch level {
        case .debug: return "DEBUG"
        case .info: return "INFO"
        case .error: return "ERROR"
        case .fault: return "FAULT"
        default: return "WARNING"
        }
    }
    
    // MARK: - API publique
    
    /// Journalise un message de débogage
    ///
    /// Les messages de débogage sont utilisés pour le développement et le diagnostic.
    /// Ils ne devraient pas apparaître dans les versions de production.
    ///
    /// - Parameters:
    ///   - message: Message à journaliser
    ///   - category: Catégorie du message (défaut: "debug")
    ///   - privacy: Niveau de confidentialité (défaut: .public)
    ///   - file: Fichier source (automatique)
    ///   - line: Numéro de ligne (automatique)
    ///   - function: Fonction appelante (automatique)
    static func debug(
        _ message: String,
        category: String = "debug",
        privacy: Privacy = .public,
        file: String = #fileID,
        line: Int = #line,
        function: String = #function
    ) {
        switch privacy {
        case .public, .auto:
            log(level: .debug, message: message, category: category, file: file, line: line, function: function)
        case .private :
            logPrivate(level: .debug, message: message, category: category, file: file, line: line, function: function)
        case .sensitive:
            logSensitive(level: .debug, message: message, category: category, file: file, line: line, function: function)

        }
    }
    
    /// Journalise un message d'information
    ///
    /// Les messages d'information indiquent des événements normaux du cycle de vie de l'application.
    ///
    /// - Parameters:
    ///   - message: Message à journaliser
    ///   - category: Catégorie du message (défaut: "info")
    ///   - privacy: Niveau de confidentialité (défaut: .public)
    ///   - file: Fichier source (automatique)
    ///   - line: Numéro de ligne (automatique)
    ///   - function: Fonction appelante (automatique)
    static func info(
        _ message: String,
        category: String = "info",
        privacy: Privacy = .public,
        file: String = #fileID,
        line: Int = #line,
        function: String = #function
    ) {
        switch privacy {
        case .public, .auto:
            log(level: .info, message: message, category: category, file: file, line: line, function: function)
        case .private:
            logPrivate(level: .info, message: message, category: category, file: file, line: line, function: function)
        case .sensitive:
            logSensitive(level: .info, message: message, category: category, file: file, line: line, function: function)
        }
    }
    
    /// Journalise un message d'avertissement
    ///
    /// Les avertissements indiquent des problèmes potentiels qui ne bloquent pas le fonctionnement.
    ///
    /// - Parameters:
    ///   - message: Message à journaliser
    ///   - category: Catégorie du message (défaut: "warning")
    ///   - privacy: Niveau de confidentialité (défaut: .public)
    ///   - file: Fichier source (automatique)
    ///   - line: Numéro de ligne (automatique)
    ///   - function: Fonction appelante (automatique)
    static func warning(
        _ message: String,
        category: String = "warning",
        privacy: Privacy = .public,
        file: String = #fileID,
        line: Int = #line,
        function: String = #function
    ) {
        switch privacy {
        case .public, .auto:
            log(level: .default, message: message, category: category, file: file, line: line, function: function)
        case .private:
            logPrivate(level: .default, message: message, category: category, file: file, line: line, function: function)
        case .sensitive:
            logSensitive(level: .default, message: message, category: category, file: file, line: line, function: function)
        }
    }
    
    /// Journalise un message d'erreur
    ///
    /// Les erreurs indiquent des problèmes qui empêchent certaines fonctionnalités de l'application.
    ///
    /// - Parameters:
    ///   - message: Message à journaliser
    ///   - category: Catégorie du message (défaut: "error")
    ///   - privacy: Niveau de confidentialité (défaut: .private)
    ///   - file: Fichier source (automatique)
    ///   - line: Numéro de ligne (automatique)
    ///   - function: Fonction appelante (automatique)
    static func error(
        _ message: String,
        category: String = "error",
        privacy: Privacy = .private,
        file: String = #fileID,
        line: Int = #line,
        function: String = #function
    ) {
        switch privacy {
        case .public, .auto:
            log(level: .error, message: message, category: category, file: file, line: line, function: function)
        case .private:
            logPrivate(level: .error, message: message, category: category, file: file, line: line, function: function)
        case .sensitive:
            logSensitive(level: .error, message: message, category: category, file: file, line: line, function: function)
        }
    }
    
    /// Journalise un message critique
    ///
    /// Les messages critiques indiquent des problèmes graves qui compromettent l'application.
    ///
    /// - Parameters:
    ///   - message: Message à journaliser
    ///   - category: Catégorie du message (défaut: "critical")
    ///   - privacy: Niveau de confidentialité (défaut: .sensitive)
    ///   - file: Fichier source (automatique)
    ///   - line: Numéro de ligne (automatique)
    ///   - function: Fonction appelante (automatique)
    static func fault(
        _ message: String,
        category: String = "critical",
        privacy: Privacy = .sensitive,
        file: String = #fileID,
        line: Int = #line,
        function: String = #function
    ) {
        switch privacy {
        case .public, .auto:
            log(level: .fault, message: message, category: category, file: file, line: line, function: function)
        case .private:
            logPrivate(level: .fault, message: message, category: category, file: file, line: line, function: function)
        case .sensitive:
            logSensitive(level: .fault, message: message, category: category, file: file, line: line, function: function)
        }
    }
}

/// Extension pour les loggers prédéfinis
extension Logger {
    /// Identifiant du sous-système pour la journalisation
    private static var subsystem = Bundle.main.bundleIdentifier ?? "com.railmap.ios"
    
    /// Logger pour les événements du cycle de vie des vues
    static let viewCycle = Logger(subsystem: subsystem, category: "viewcycle")
    
    /// Logger pour les statistiques d'utilisation
    static let statistics = Logger(subsystem: subsystem, category: "statistics")
}
