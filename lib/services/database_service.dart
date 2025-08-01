import 'package:postgres/postgres.dart';
import 'config_service.dart';

enum DbConnectionRole {
  public,
  admin,
}

class DatabaseService {
  final ConfigService _config;
  final _host = 'localhost';
  final _port = 5432;
  final _databaseName = 'alfalite_db';

  PostgreSQLConnection? _connection;

  DatabaseService(this._config);

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