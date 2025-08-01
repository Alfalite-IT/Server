import 'package:bcrypt/bcrypt.dart';

void main() {
  final password = 'T3sT2025!';
  final hash = BCrypt.hashpw(password, BCrypt.gensalt());
  
  print('--- BCrypt Hash Verification ---');
  print('Password to hash: $password');
  print('Generated Hash: $hash');
  print('---');
  print('NOTE: Because bcrypt includes a random salt, this hash will be different every time you run it.');
  print('We will now check if your password matches the known hash.');

  final knownHash = r'$2a$10$wSjCg3oX.ASgXg59HLL3FeaVf.IFN1p33GZ2u4u.DqX9aWWiJpSke';
  final doTheyMatch = BCrypt.checkpw(password, knownHash);

  print('');
  print('--- Verification Check ---');
  print('Does "$password" match the known hash?');
  print('Result: $doTheyMatch');
  print('---');
}
