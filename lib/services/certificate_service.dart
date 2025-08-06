import 'dart:io';
import 'dart:async';
import 'package:shelf/shelf.dart';
import 'config_service.dart';

class CertificateService {
  final ConfigService _configService;
  final String _certDir = 'certs';

  CertificateService(this._configService);

  /// Get certificate file paths based on domain
  String getCertPath(String domain) {
    if (domain.contains('admin.alfalite.com')) {
      return _configService.certPathAdmin;
    } else {
      return _configService.certPathApp;
    }
  }

  String getKeyPath(String domain) {
    if (domain.contains('admin.alfalite.com')) {
      return _configService.keyPathAdmin;
    } else {
      return _configService.keyPathApp;
    }
  }

  /// Extract domain from request context
  static String getDomainFromRequest(Request request) {
    return request.context['domain'] as String? ?? 'app.alfalite.com';
  }

  /// Check if certificates exist and are valid for a specific domain
  Future<bool> hasValidCertificates(String domain) async {
    try {
      final certFile = File(getCertPath(domain));
      final keyFile = File(getKeyPath(domain));
      
      if (!await certFile.exists() || !await keyFile.exists()) {
        return false;
      }

      // For now, just check if files exist
      // In production, you'd want to check certificate expiry
      return true;
    } catch (e) {
      print('Error checking certificates for $domain: $e');
      return false;
    }
  }

  /// Check if certificates exist for both domains
  Future<bool> hasValidCertificatesForAllDomains() async {
    final appValid = await hasValidCertificates('app.alfalite.com');
    final adminValid = await hasValidCertificates('admin.alfalite.com');
    return appValid && adminValid;
  }

  /// Generate Let's Encrypt certificate for a specific domain
  Future<bool> generateCertificate(String domain) async {
    try {
      print('🔐 Generating Let\'s Encrypt certificate for $domain...');
      
      // Create certs directory
      final certDir = Directory(_certDir);
      if (!await certDir.exists()) {
        await certDir.create(recursive: true);
      }

      // For development, create self-signed certificate
      if (_configService.environment == 'development') {
        return await _generateSelfSignedCertificate(domain);
      }

      // For production, use Let's Encrypt
      return await _generateLetsEncryptCertificate(domain);
    } catch (e) {
      print('❌ Error generating certificate for $domain: $e');
      return false;
    }
  }

  /// Generate self-signed certificate for development
  Future<bool> _generateSelfSignedCertificate(String domain) async {
    try {
      print('🔐 Generating self-signed certificate for $domain...');
      
      final certPath = getCertPath(domain);
      final keyPath = getKeyPath(domain);
      
      // Use OpenSSL to generate self-signed certificate
      final result = await Process.run('openssl', [
        'req', '-x509', '-newkey', 'rsa:4096', '-keyout', keyPath,
        '-out', certPath, '-days', '365', '-nodes',
        '-subj', '/C=ES/ST=Huelva/L=Rociana/O=Alfalite/CN=$domain'
      ]);

      if (result.exitCode == 0) {
        print('✅ Self-signed certificate generated successfully for $domain');
        return true;
      } else {
        print('❌ Failed to generate self-signed certificate for $domain: ${result.stderr}');
        return false;
      }
    } catch (e) {
      print('❌ Error generating self-signed certificate for $domain: $e');
      return false;
    }
  }

  /// Generate Let's Encrypt certificate for production
  Future<bool> _generateLetsEncryptCertificate(String domain) async {
    try {
      print('🔐 Generating Let\'s Encrypt certificate for $domain...');
      
      // This is a simplified version - in production you'd want to use
      // a proper ACME client library or certbot
      
      // For now, we'll create a placeholder that indicates
      // the certificate should be generated using certbot
      print('📝 For production, please run:');
      print('   sudo certbot certonly --standalone -d $domain --email info@alfalite.com');
      print('   sudo cp /etc/letsencrypt/live/$domain/fullchain.pem ${getCertPath(domain)}');
      print('   sudo cp /etc/letsencrypt/live/$domain/privkey.pem ${getKeyPath(domain)}');
      
      return false; // Indicate manual setup is needed
    } catch (e) {
      print('❌ Error generating Let\'s Encrypt certificate for $domain: $e');
      return false;
    }
  }

  /// Get SSL context for HTTPS server based on domain
  SecurityContext? getSecurityContext(String domain) {
    try {
      final certFile = File(getCertPath(domain));
      final keyFile = File(getKeyPath(domain));
      
      if (!certFile.existsSync() || !keyFile.existsSync()) {
        print('⚠️  Certificate files not found for $domain. Using HTTP only.');
        return null;
      }

      final context = SecurityContext(withTrustedRoots: true);
      context.useCertificateChain(getCertPath(domain));
      context.usePrivateKey(getKeyPath(domain));
      
      print('✅ SSL context created successfully for $domain');
      return context;
    } catch (e) {
      print('❌ Error creating SSL context for $domain: $e');
      return null;
    }
  }

  /// Get SSL context for the default domain (app.alfalite.com)
  SecurityContext? getDefaultSecurityContext() {
    return getSecurityContext('app.alfalite.com');
  }

  /// Setup automatic certificate renewal
  Future<void> setupAutoRenewal() async {
    if (_configService.environment == 'development') {
      print('ℹ️  Auto-renewal not needed for development');
      return;
    }

    print('🔄 Setting up automatic certificate renewal...');
    print('📝 For production, add to crontab:');
    print('   0 12 * * * certbot renew --quiet && systemctl reload alfalite-server');
  }
} 