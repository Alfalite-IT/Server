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

  // Database credentials
  late final String dbPublicUser;
  late final String dbPublicPassword;
  late final String dbAdminUser;
  late final String dbAdminPassword;

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

    // SMTP Config
    smtpHost = dotEnv['SMTP_HOST'] ?? '';
    smtpPort = int.tryParse(dotEnv['SMTP_PORT'] ?? '587') ?? 587;
    smtpUsername = dotEnv['SMTP_USERNAME'] ?? '';
    smtpPassword = dotEnv['SMTP_PASSWORD'] ?? '';
    companyEmail = dotEnv['COMPANY_EMAIL'] ?? '';

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