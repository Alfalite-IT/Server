import 'dart:convert';
import 'package:shelf/shelf.dart';
import '../services/auth_service.dart';
import '../services/jwt_service.dart';

class AuthHandlers {
  final AuthService _authService;
  final JwtService _jwtService;

  AuthHandlers(this._authService, this._jwtService);

  Future<Response> loginHandler(Request request) async {
    try {
      final body = await request.readAsString();
      final params = json.decode(body);
      final username = params['username'] as String?;
      final password = params['password'] as String?;

      if (username == null || password == null) {
        return Response(400, body: 'Missing username or password');
      }

      final userId = await _authService.signIn(username, password);

      if (userId != null) {
        final token = _jwtService.generateToken(userId);
        return Response.ok(json.encode({'token': token}));
      } else {
        return Response(401, body: 'Invalid credentials');
      }
    } catch (e) {
      print('Login error: $e');
      return Response.internalServerError(body: 'An error occurred during login.');
    }
  }
} 