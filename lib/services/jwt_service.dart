import 'package:jaguar_jwt/jaguar_jwt.dart';
import 'config_service.dart';

class JwtService {
  final String _secret;

  JwtService(ConfigService config) : _secret = config.jwtSecret;

  String generateToken(int userId) {
    final claimSet = JwtClaim(
      subject: userId.toString(),
      issuer: 'alfalite_server',
      maxAge: const Duration(minutes: 5), // Token is valid for 5 minutes
    );
    return issueJwtHS256(claimSet, _secret);
  }

  JwtClaim verifyToken(String token) {
    try {
      final claim = verifyJwtHS256Signature(token, _secret);
      // Manually validate the expiry. The package does not throw on its own for this.
      claim.validate(issuer: 'alfalite_server');
      return claim;
    } catch (e) {
      // Re-throw the exception to be handled by the caller (e.g., the auth middleware)
      // This ensures that failed validation is always an exceptional event.
      throw Exception('Invalid token: $e');
    }
  }
} 