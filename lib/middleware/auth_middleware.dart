import 'package:shelf/shelf.dart';
import '../services/jwt_service.dart';

Middleware createAuthMiddleware(JwtService jwtService) {
  return (Handler innerHandler) {
    return (Request request) {
      final authHeader = request.headers['authorization'];
      if (authHeader == null || !authHeader.startsWith('Bearer ')) {
        return Response.forbidden('Not authorized. No token provided.');
      }

      final token = authHeader.substring(7); // Remove 'Bearer ' prefix

      try {
        jwtService.verifyToken(token);
        // If token is valid, proceed to the handler
        return innerHandler(request);
      } catch (e) {
        // If token is invalid or expired, deny access
        return Response.forbidden('Not authorized. Invalid token: ${e.toString()}');
      }
    };
  };
} 