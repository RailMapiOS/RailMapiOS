//
//  Logger.swift
//  RailMapiOS
//
//  Created by Jérémie Patot on 14/03/2025.
//

import OSLog

/// Un système de journalisation unifié pour RailMapiOS
struct LogManager {
    // MARK: - Propriétés privées
    
    /// Identifiant du sous-système pour la journalisation
    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.railmap.ios"
    
    // Cache de loggers pour éviter de créer de nouvelles instances à chaque appel
    @MainActor private static var loggerCache: [String: Logger] = [:]
    
    // MARK: - Types internes
    
    /// Définit les niveaux de confidentialité pour les messages journalisés
    enum Privacy {
        case `public`
        case `private`
        case sensitive
        case auto
    }
    
    // MARK: - Méthodes privées
    
    /// Obtient un logger pour une catégorie spécifique
    @MainActor private static func getLogger(for category: String) -> Logger {
        if let cachedLogger = loggerCache[category] {
            return cachedLogger
        }
        
        let logger = Logger(subsystem: subsystem, category: category)
        loggerCache[category] = logger
        return logger
    }
    
    /// Retourne le nom du niveau de journalisation
    private static func levelName(for level: OSLogType) -> String {
        switch level {
        case .debug: return "DEBUG"
        case .info: return "INFO"
        case .error: return "ERROR"
        case .fault: return "FAULT"
        default: return "WARNING"
        }
    }
    
    /// Prépare le message formaté
    private static func formatMessage(
        level: OSLogType,
        message: String,
        file: String,
        line: Int,
        function: String
    ) -> String {
        let fileInfo = "(\(file):\(line) - \(function))"
        let levelString = levelName(for: level)
        
        let emoji: String
        switch level {
        case .debug: emoji = "🔍"
        case .info: emoji = "ℹ️"
        case .error: emoji = "🔥"
        case .fault: emoji = "🚨"
        default: emoji = "⚠️"
        }
        
        return "\(emoji) [\(levelString)] \(fileInfo) \(message)"
    }
    
    /// Journalise un message avec le niveau et la confidentialité spécifiés
    private static func logMessage(
        level: OSLogType,
        message: String,
        category: String,
        privacy: Privacy,
        file: String,
        line: Int,
        function: String
    ) async {
        let formattedMessage = formatMessage(
            level: level,
            message: message,
            file: file,
            line: line,
            function: function
        )
        
        let logger = await getLogger(for: category)
        
        switch (level, privacy) {
        case (.debug, .public), (.debug, .auto):
            logger.debug("\(formattedMessage, privacy: .auto)")
        case (.debug, .private):
            logger.debug("\(formattedMessage, privacy: .private)")
        case (.debug, .sensitive):
            logger.debug("\(formattedMessage, privacy: .sensitive)")
            
        case (.info, .public), (.info, .auto):
            logger.info("\(formattedMessage, privacy: .auto)")
        case (.info, .private):
            logger.info("\(formattedMessage, privacy: .private)")
        case (.info, .sensitive):
            logger.info("\(formattedMessage, privacy: .sensitive)")
            
        case (.error, .public), (.error, .auto):
            logger.error("\(formattedMessage, privacy: .auto)")
        case (.error, .private):
            logger.error("\(formattedMessage, privacy: .private)")
        case (.error, .sensitive):
            logger.error("\(formattedMessage, privacy: .sensitive)")
            
        case (.fault, .public), (.fault, .auto):
            logger.fault("\(formattedMessage, privacy: .auto)")
        case (.fault, .private):
            logger.fault("\(formattedMessage, privacy: .private)")
        case (.fault, .sensitive):
            logger.fault("\(formattedMessage, privacy: .sensitive)")
            
        case (_, .public), (_, .auto):
            logger.warning("\(formattedMessage, privacy: .auto)")
        case (_, .private):
            logger.warning("\(formattedMessage, privacy: .private)")
        case (_, .sensitive):
            logger.warning("\(formattedMessage, privacy: .sensitive)")
        }
    }
    
    // MARK: - API publique
    
    /// Journalise un message de débogage
    static func debug(
        _ message: String,
        category: String = "debug",
        privacy: Privacy = .public,
        file: String = #fileID,
        line: Int = #line,
        function: String = #function
    ) {
        Task {
            await logMessage(
                level: .debug,
                message: message,
                category: category,
                privacy: privacy,
                file: file,
                line: line,
                function: function
            )
        }
    }
    
    /// Journalise un message d'information
    static func info(
        _ message: String,
        category: String = "info",
        privacy: Privacy = .public,
        file: String = #fileID,
        line: Int = #line,
        function: String = #function
    ) {
        Task {
            await logMessage(
                level: .info,
                message: message,
                category: category,
                privacy: privacy,
                file: file,
                line: line,
                function: function
            )
        }
    }
    
    /// Journalise un message d'avertissement
    static func warning(
        _ message: String,
        category: String = "warning",
        privacy: Privacy = .public,
        file: String = #fileID,
        line: Int = #line,
        function: String = #function
    ) {
        Task {
            await logMessage(
                level: .default,
                message: message,
                category: category,
                privacy: privacy,
                file: file,
                line: line,
                function: function
            )
        }
    }
    
    /// Journalise un message d'erreur
    static func error(
        _ message: String,
        category: String = "error",
        privacy: Privacy = .private,
        file: String = #fileID,
        line: Int = #line,
        function: String = #function
    ) {
        Task {
            await logMessage(
                level: .error,
                message: message,
                category: category,
                privacy: privacy,
                file: file,
                line: line,
                function: function
            )
        }
    }
    
    /// Journalise un message critique
    static func fault(
        _ message: String,
        category: String = "critical",
        privacy: Privacy = .sensitive,
        file: String = #fileID,
        line: Int = #line,
        function: String = #function
    ) {
        Task {
            await logMessage(
                level: .fault,
                message: message,
                category: category,
                privacy: privacy,
                file: file,
                line: line,
                function: function
            )
        }
    }
}

/// Extension pour les loggers prédéfinis
extension Logger {
    /// Identifiant du sous-système pour la journalisation
    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.railmap.ios"
    
    /// Logger pour les événements du cycle de vie des vues
    static let viewCycle = Logger(subsystem: subsystem, category: "viewcycle")
    
    /// Logger pour les statistiques d'utilisation
    static let statistics = Logger(subsystem: subsystem, category: "statistics")
}
