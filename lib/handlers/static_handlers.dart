import 'package:shelf/shelf.dart';

class StaticHandlers {
  Response rootHandler(Request req) {
    return Response.ok('Hello, World!\n');
  }

  Response echoHandler(Request request, String message) {
    return Response.ok('$message\n');
  }
} 