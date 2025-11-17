<?php
/**
 * ═══════════════════════════════════════════════════════════════════════════
 * BOLT.DIY USER MANAGER v2.0 - Classe Logger
 * © Copyright Nbility 2025 - contact@nbility.fr
 * 
 * Système de logging PSR-3 compatible
 * ═══════════════════════════════════════════════════════════════════════════
 */

declare(strict_types=1);

namespace App\Utils;

/**
 * Classe Logger - Système de logs
 */
class Logger
{
    /**
     * Niveaux de log (PSR-3)
     */
    public const EMERGENCY = 'emergency';
    public const ALERT = 'alert';
    public const CRITICAL = 'critical';
    public const ERROR = 'error';
    public const WARNING = 'warning';
    public const NOTICE = 'notice';
    public const INFO = 'info';
    public const DEBUG = 'debug';

    /**
     * Priorités des niveaux de log
     */
    private const LOG_LEVELS = [
        self::EMERGENCY => 800,
        self::ALERT => 700,
        self::CRITICAL => 600,
        self::ERROR => 500,
        self::WARNING => 400,
        self::NOTICE => 300,
        self::INFO => 200,
        self::DEBUG => 100,
    ];

    /**
     * Répertoire de logs
     */
    private static ?string $logDir = null;

    /**
     * Niveau de log minimum
     */
    private static string $minLevel = self::INFO;

    /**
     * Initialiser le logger
     * 
     * @param string|null $logDir Répertoire de logs
     * @param string $minLevel Niveau minimum
     */
    public static function init(?string $logDir = null, string $minLevel = self::INFO): void
    {
        self::$logDir = $logDir ?? (defined('APP_LOGS_DIR') ? APP_LOGS_DIR : __DIR__ . '/../../logs');
        self::$minLevel = $minLevel;

        // Créer le répertoire si nécessaire
        if (!is_dir(self::$logDir)) {
            mkdir(self::$logDir, 0755, true);
        }
    }

    /**
     * Logger un message
     * 
     * @param string $level Niveau de log
     * @param string $message Message
     * @param array $context Contexte additionnel
     */
    public static function log(string $level, string $message, array $context = []): void
    {
        // Initialiser si pas encore fait
        if (self::$logDir === null) {
            self::init();
        }

        // Vérifier le niveau de log
        if (!self::shouldLog($level)) {
            return;
        }

        // Formatter le message
        $formattedMessage = self::formatMessage($level, $message, $context);

        // Écrire dans le fichier de log
        self::writeToFile($level, $formattedMessage);
    }

    /**
     * Vérifier si on doit logger ce niveau
     * 
     * @param string $level Niveau de log
     * @return bool
     */
    private static function shouldLog(string $level): bool
    {
        $currentPriority = self::LOG_LEVELS[$level] ?? 0;
        $minPriority = self::LOG_LEVELS[self::$minLevel] ?? 0;

        return $currentPriority >= $minPriority;
    }

    /**
     * Formatter le message de log
     * 
     * @param string $level Niveau
     * @param string $message Message
     * @param array $context Contexte
     * @return string
     */
    private static function formatMessage(string $level, string $message, array $context): string
    {
        $timestamp = date('Y-m-d H:i:s');
        $levelUpper = strtoupper($level);

        // Remplacer les placeholders dans le message
        $message = self::interpolate($message, $context);

        // Format: [2025-01-15 12:30:45] [ERROR] Message d'erreur
        $formatted = "[{$timestamp}] [{$levelUpper}] {$message}";

        // Ajouter le contexte si présent
        if (!empty($context)) {
            $formatted .= " " . json_encode($context, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
        }

        return $formatted;
    }

    /**
     * Interpoler les placeholders dans le message
     * 
     * @param string $message Message
     * @param array $context Contexte
     * @return string
     */
    private static function interpolate(string $message, array $context): string
    {
        $replace = [];
        foreach ($context as $key => $val) {
            if (is_string($val) || is_numeric($val) || (is_object($val) && method_exists($val, '__toString'))) {
                $replace['{' . $key . '}'] = $val;
            }
        }

        return strtr($message, $replace);
    }

    /**
     * Écrire dans le fichier de log
     * 
     * @param string $level Niveau
     * @param string $message Message formaté
     */
    private static function writeToFile(string $level, string $message): void
    {
        // Nom du fichier de log
        $date = date('Y-m-d');
        $filename = self::$logDir . "/{$level}_{$date}.log";

        // Fichier général
        $generalFile = self::$logDir . "/app_{$date}.log";

        // Écrire dans le fichier spécifique au niveau
        file_put_contents($filename, $message . PHP_EOL, FILE_APPEND | LOCK_EX);

        // Écrire aussi dans le fichier général
        file_put_contents($generalFile, $message . PHP_EOL, FILE_APPEND | LOCK_EX);

        // Rotation des logs (garder 30 jours)
        self::rotateLogs();
    }

    /**
     * Rotation des logs (supprimer les vieux fichiers)
     */
    private static function rotateLogs(): void
    {
        static $lastRotation = null;

        // Ne faire la rotation qu'une fois par jour
        if ($lastRotation === date('Y-m-d')) {
            return;
        }

        $lastRotation = date('Y-m-d');
        $maxAge = 30 * 24 * 3600; // 30 jours

        $files = glob(self::$logDir . '/*.log');
        foreach ($files as $file) {
            if (filemtime($file) < time() - $maxAge) {
                unlink($file);
            }
        }
    }

    // ───────────────────────────────────────────────────────────────────────
    // Méthodes de convenance (PSR-3)
    // ───────────────────────────────────────────────────────────────────────

    public static function emergency(string $message, array $context = []): void
    {
        self::log(self::EMERGENCY, $message, $context);
    }

    public static function alert(string $message, array $context = []): void
    {
        self::log(self::ALERT, $message, $context);
    }

    public static function critical(string $message, array $context = []): void
    {
        self::log(self::CRITICAL, $message, $context);
    }

    public static function error(string $message, array $context = []): void
    {
        self::log(self::ERROR, $message, $context);
    }

    public static function warning(string $message, array $context = []): void
    {
        self::log(self::WARNING, $message, $context);
    }

    public static function notice(string $message, array $context = []): void
    {
        self::log(self::NOTICE, $message, $context);
    }

    public static function info(string $message, array $context = []): void
    {
        self::log(self::INFO, $message, $context);
    }

    public static function debug(string $message, array $context = []): void
    {
        self::log(self::DEBUG, $message, $context);
    }
}

/**
 * ═══════════════════════════════════════════════════════════════════════════
 * FIN DE LA CLASSE LOGGER
 * ═══════════════════════════════════════════════════════════════════════════
 */
