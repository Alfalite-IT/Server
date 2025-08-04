import 'package:dotenv/dotenv.dart';

class ConfigService {
  late final String jwtSecret;
  late final List<String> allowedOrigins;

  late final String environment;
  late final String smtpHost;
  late final int smtpPort;
  late final String smtpUsername;
  late final String smtpPassword;
  late final String companyEmail;
  
  // HTTPS Configuration
  late final bool useHttps;
  late final int httpsPort;
  late final String certPath;
  late final String keyPath;
  
  // Email abuse prevention
  late final int emailRateLimit;
  late final int maxRequestSize;

  // Database credentials
  late final String dbPublicUser;
  late final String dbPublicPassword;
  late final String dbAdminUser;
  late final String dbAdminPassword;
  
  // Database connection details
  late final String dbHost;
  late final int dbPort;
  late final String dbName;

  ConfigService() {
    // Note: This assumes the .env file is in the server's root directory.
    // In production, these will be real environment variables.
    final dotEnv = DotEnv(includePlatformEnvironment: true)..load();
    
    // General Config
    environment = dotEnv['ENVIRONMENT'] ?? 'development';

    // JWT Config
    final secret = dotEnv['JWT_SECRET_KEY'];
    if (secret == null || secret.isEmpty) {
      throw Exception('JWT_SECRET_KEY is not set in the environment.');
    }
    jwtSecret = secret;

    // CORS Config
    final origins = dotEnv['ALLOWED_ORIGINS'] ?? '*';
    allowedOrigins = origins.split(',').map((e) => e.trim()).toList();

    // Database Config
    dbPublicUser = dotEnv['DB_PUBLIC_USER'] ?? '';
    dbPublicPassword = dotEnv['DB_PUBLIC_PASSWORD'] ?? '';
    dbAdminUser = dotEnv['DB_ADMIN_USER'] ?? '';
    dbAdminPassword = dotEnv['DB_ADMIN_PASSWORD'] ?? '';
    
    // Database connection details
    dbHost = dotEnv['DB_HOST'] ?? 'localhost';
    dbPort = int.tryParse(dotEnv['DB_PORT'] ?? '5432') ?? 5432;
    dbName = dotEnv['DB_NAME'] ?? 'alfalite_db';

    // SMTP Config
    smtpHost = dotEnv['SMTP_HOST'] ?? '';
    smtpPort = int.tryParse(dotEnv['SMTP_PORT'] ?? '587') ?? 587;
    smtpUsername = dotEnv['SMTP_USERNAME'] ?? '';
    smtpPassword = dotEnv['SMTP_PASSWORD'] ?? '';
    companyEmail = dotEnv['COMPANY_EMAIL'] ?? '';

    // HTTPS Configuration
    useHttps = dotEnv['USE_HTTPS'] == 'true' || environment == 'production';
    httpsPort = int.tryParse(dotEnv['HTTPS_PORT'] ?? '1337') ?? 1337;
    certPath = dotEnv['CERT_PATH'] ?? 'certs/app.alfalite.com.crt';
    keyPath = dotEnv['KEY_PATH'] ?? 'certs/app.alfalite.com.key';

    // Email abuse prevention
    emailRateLimit = int.tryParse(dotEnv['EMAIL_RATE_LIMIT'] ?? '10') ?? 10;
    maxRequestSize = int.tryParse(dotEnv['MAX_REQUEST_SIZE'] ?? '10485760') ?? 10485760; // 10MB

    // Only require SMTP credentials in production
    if (environment == 'production') {
      if (smtpHost.isEmpty || smtpUsername.isEmpty || smtpPassword.isEmpty || companyEmail.isEmpty) {
        throw Exception('Production environment requires all SMTP environment variables to be set.');
      }
    }

    // Always require database credentials
    if (dbPublicUser.isEmpty || dbPublicPassword.isEmpty || dbAdminUser.isEmpty || dbAdminPassword.isEmpty) {
      throw Exception('Database credentials are not fully set in the environment.');
    }
  }
} 