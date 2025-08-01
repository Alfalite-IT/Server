import 'package:postgres/postgres.dart';
import 'config_service.dart';

enum DbConnectionRole {
  public,
  admin,
}

class DatabaseService {
  final ConfigService _config;
  late final String _host;
  late final int _port;
  late final String _databaseName;

  PostgreSQLConnection? _connection;

  DatabaseService(this._config) {
    // Get database connection details from environment
    _host = _config.dbHost;
    _port = _config.dbPort;
    _databaseName = _config.dbName;
  }

  Future<PostgreSQLConnection> openConnection(DbConnectionRole role) async {
    final String username;
    final String password;

    switch (role) {
      case DbConnectionRole.public:
        username = _config.dbPublicUser;
        password = _config.dbPublicPassword;
        break;
      case DbConnectionRole.admin:
        username = _config.dbAdminUser;
        password = _config.dbAdminPassword;
        break;
    }

    _connection = PostgreSQLConnection(
      _host,
      _port,
      _databaseName,
      username: username,
      password: password,
    );
    await _connection!.open();
    return _connection!;
  }

  // Closes the current connection if it's open.
  Future<void> closeConnection() async {
    await _connection?.close();
  }
} 