import 'dart:io';
import 'dart:async';
import 'config_service.dart';

class CertificateService {
  final ConfigService _configService;
  final String _certDir = 'certs';
  final String _domain;
  final String _email;

  CertificateService(this._configService)
      : _domain = _configService.environment == 'production' 
          ? 'app.alfalite.com' 
          : 'localhost',
        _email = 'info@alfalite.com';

  /// Get certificate file paths
  String get certPath => '$_certDir/$_domain.crt';
  String get keyPath => '$_certDir/$_domain.key';

  /// Check if certificates exist and are valid
  Future<bool> hasValidCertificates() async {
    try {
      final certFile = File(certPath);
      final keyFile = File(keyPath);
      
      if (!await certFile.exists() || !await keyFile.exists()) {
        return false;
      }

      // For now, just check if files exist
      // In production, you'd want to check certificate expiry
      return true;
    } catch (e) {
      print('Error checking certificates: $e');
      return false;
    }
  }

  /// Generate Let's Encrypt certificate
  Future<bool> generateCertificate() async {
    try {
      print('🔐 Generating Let\'s Encrypt certificate for $_domain...');
      
      // Create certs directory
      final certDir = Directory(_certDir);
      if (!await certDir.exists()) {
        await certDir.create(recursive: true);
      }

      // For development, create self-signed certificate
      if (_configService.environment == 'development') {
        return await _generateSelfSignedCertificate();
      }

      // For production, use Let's Encrypt
      return await _generateLetsEncryptCertificate();
    } catch (e) {
      print('❌ Error generating certificate: $e');
      return false;
    }
  }

  /// Generate self-signed certificate for development
  Future<bool> _generateSelfSignedCertificate() async {
    try {
      print('🔐 Generating self-signed certificate for development...');
      
      // Use OpenSSL to generate self-signed certificate
      final result = await Process.run('openssl', [
        'req', '-x509', '-newkey', 'rsa:4096', '-keyout', keyPath,
        '-out', certPath, '-days', '365', '-nodes',
        '-subj', '/C=ES/ST=Huelva/L=Rociana/O=Alfalite/CN=$_domain'
      ]);

      if (result.exitCode == 0) {
        print('✅ Self-signed certificate generated successfully');
        return true;
      } else {
        print('❌ Failed to generate self-signed certificate: ${result.stderr}');
        return false;
      }
    } catch (e) {
      print('❌ Error generating self-signed certificate: $e');
      return false;
    }
  }

  /// Generate Let's Encrypt certificate for production
  Future<bool> _generateLetsEncryptCertificate() async {
    try {
      print('🔐 Generating Let\'s Encrypt certificate for $_domain...');
      
      // This is a simplified version - in production you'd want to use
      // a proper ACME client library or certbot
      
      // For now, we'll create a placeholder that indicates
      // the certificate should be generated using certbot
      print('📝 For production, please run:');
      print('   sudo certbot certonly --standalone -d $_domain --email $_email');
      print('   sudo cp /etc/letsencrypt/live/$_domain/fullchain.pem $certPath');
      print('   sudo cp /etc/letsencrypt/live/$_domain/privkey.pem $keyPath');
      
      return false; // Indicate manual setup is needed
    } catch (e) {
      print('❌ Error generating Let\'s Encrypt certificate: $e');
      return false;
    }
  }

  /// Get SSL context for HTTPS server
  SecurityContext? getSecurityContext() {
    try {
      final certFile = File(certPath);
      final keyFile = File(keyPath);
      
      if (!certFile.existsSync() || !keyFile.existsSync()) {
        print('⚠️  Certificate files not found. Using HTTP only.');
        return null;
      }

      final context = SecurityContext(withTrustedRoots: true);
      context.useCertificateChain(certPath);
      context.usePrivateKey(keyPath);
      
      print('✅ SSL context created successfully');
      return context;
    } catch (e) {
      print('❌ Error creating SSL context: $e');
      return null;
    }
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