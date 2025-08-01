import 'package:bcrypt/bcrypt.dart';
import 'database_service.dart';

class AuthService {
  final DatabaseService _dbService;

  AuthService(this._dbService);

  Future<Map<String, dynamic>?> _getUserByUsername(String username) async {
    final connection = await _dbService.openConnection(DbConnectionRole.admin);
    try {
      final result = await connection.query(
        "SELECT id, password_hash FROM users WHERE username = @username",
        substitutionValues: {'username': username},
      );
      if (result.isNotEmpty) {
        return result.first.toColumnMap();
      }
      return null;
    } finally {
      await _dbService.closeConnection();
    }
  }

  Future<int?> signIn(String username, String password) async {
    final userData = await _getUserByUsername(username);
    if (userData == null) {
      return null; // User not found
    }

    final storedHash = userData['password_hash'] as String;
    
    // BCrypt.checkpw securely compares the plain-text password with the stored hash.
    if (BCrypt.checkpw(password, storedHash)) {
      return userData['id'] as int; // Return user ID on success
    }

    return null; // Password incorrect
  }
} 