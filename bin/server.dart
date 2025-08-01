import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_static/shelf_static.dart';
import 'package:alfalite_server/api_router.dart';
import 'package:alfalite_server/services/config_service.dart';
import 'package:alfalite_server/services/database_service.dart';

// This function creates a dynamic CORS middleware.
Middleware createCorsMiddleware(ConfigService config) {
  return (innerHandler) {
    return (request) async {
      final origin = request.headers['Origin'];
      final isAllowed = origin != null && (config.allowedOrigins.contains(origin) || config.allowedOrigins.contains('*'));

      // For any request, if the origin is not allowed, block it immediately.
      // An exception is made for requests without an Origin header, which are typically
      // same-origin requests or non-browser clients like curl.
      if (origin != null && !isAllowed) {
        return Response.forbidden('Origin $origin is not allowed by CORS policy.');
      }

      // Handle preflight (OPTIONS) requests.
      if (request.method == 'OPTIONS') {
        // The check above already confirmed the origin is allowed if it was present.
        return Response.ok(null, headers: {
          'Access-Control-Allow-Origin': origin!, // origin cannot be null here
          'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
          'Access-Control-Allow-Headers': 'Origin, Content-Type, Authorization',
        });
      }

      // Handle actual requests.
      final response = await innerHandler(request);
      
      var newHeaders = {...response.headers};

      // Add the origin header to the actual response if it's allowed.
      if (isAllowed) {
        newHeaders['Access-Control-Allow-Origin'] = origin!;
      }
      
      // If wildcard is used, add it.
      else if (config.allowedOrigins.contains('*')) {
        newHeaders['Access-Control-Allow-Origin'] = '*';
      }

      return response.change(headers: newHeaders);
    };
  };
}

void main(List<String> args) async {
  // Initialize services and router
  final configService = ConfigService();
  final dbService = DatabaseService(configService);
  final apiRouter = ApiRouter(dbService, configService);

  // Create a static file handler for the 'public' directory
  final staticHandler = createStaticHandler('public', defaultDocument: 'index.html');

  // Use any available host or container IP (usually `0.0.0.0`).
  final ip = InternetAddress.anyIPv4;

  // Use Cascade to first attempt to serve static files, then fall back to the API.
  // This is the correct order to prevent the API's auth middleware from
  // intercepting requests for static assets like images.
  final cascade = Cascade()
      .add(staticHandler)   // First, try to serve a static file.
      .add(apiRouter.router); // If not found, fall back to the API router.

  // Configure a pipeline that logs requests and uses our router.
  final handler = const Pipeline()
      .addMiddleware(logRequests())
      .addMiddleware(createCorsMiddleware(configService)) // Use the new dynamic middleware
      .addHandler(cascade.handler);

  // For running in containers, we respect the PORT environment variable.
  final port = int.parse(Platform.environment['PORT'] ?? '8080');
  final server = await serve(handler, ip, port);
  print('Server listening on port ${server.port}');
} 