import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_static/shelf_static.dart';
import 'package:alfalite_server/api_router.dart';
import 'package:alfalite_server/services/config_service.dart';
import 'package:alfalite_server/services/database_service.dart';
import 'package:alfalite_server/services/certificate_service.dart';

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

// Middleware to extract domain information from request
Middleware createDomainMiddleware() {
  return (innerHandler) {
    return (request) async {
      // Extract domain from Host header or Origin header
      String? domain;
      
      // Try to get domain from Host header first
      final host = request.headers['Host'];
      if (host != null) {
        domain = host.split(':').first; // Remove port if present
      }
      
      // Fallback to Origin header
      if (domain == null) {
        final origin = request.headers['Origin'];
        if (origin != null) {
          final uri = Uri.parse(origin);
          domain = uri.host;
        }
      }
      
      // Store domain in request context for later use
      final context = {
        'domain': domain ?? 'app.alfalite.com', // Default to app domain
        ...request.context,
      };
      
      return await innerHandler(request.change(context: context));
    };
  };
}

void main(List<String> args) async {
  // Initialize services and router
  final configService = ConfigService();
  final dbService = DatabaseService(configService);
  final apiRouter = ApiRouter(dbService, configService);
  final certificateService = CertificateService(configService);

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
      .addMiddleware(createDomainMiddleware()) // Add domain middleware
      .addMiddleware(createCorsMiddleware(configService)) // Use the new dynamic middleware
      .addHandler(cascade.handler);

  // Check for HTTPS configuration
  final useHttps = configService.useHttps;
  
  print('🔍 Debug: Environment = ${configService.environment}');
  print('🔍 Debug: USE_HTTPS from config = ${configService.useHttps}');
  print('🔍 Debug: useHttps = $useHttps');
  
  if (useHttps) {
    // Check if certificates exist for both domains
    if (!await certificateService.hasValidCertificatesForAllDomains()) {
      print('🔐 No valid certificates found for all domains. Generating...');
      
      // Generate certificates for both domains
      final appSuccess = await certificateService.generateCertificate('app.alfalite.com');
      final adminSuccess = await certificateService.generateCertificate('admin.alfalite.com');
      
      if (!appSuccess || !adminSuccess) {
        print('⚠️  Failed to generate certificates for all domains. Starting in HTTP mode.');
        await _startHttpServer(handler, ip);
        return;
      }
    }

    // For now, use the default security context (app.alfalite.com)
    // In a more sophisticated setup, you might want to run separate servers
    // for each domain or use a reverse proxy like nginx
    final securityContext = certificateService.getDefaultSecurityContext();
    if (securityContext != null) {
      // Start HTTPS server
      final httpsPort = int.parse(Platform.environment['HTTPS_PORT'] ?? '1337');
      final httpsServer = await serve(handler, ip, httpsPort, securityContext: securityContext);
      print('🔒 HTTPS Server listening on port ${httpsServer.port}');
      print('📝 Note: Using app.alfalite.com certificate. For production, consider using nginx as reverse proxy.');
      
      // Setup auto-renewal for production
      if (configService.environment == 'production') {
        await certificateService.setupAutoRenewal();
      }
    } else {
      print('⚠️  SSL context not available. Starting in HTTP mode.');
      await _startHttpServer(handler, ip);
    }
  } else {
    // Start HTTP server for development
    await _startHttpServer(handler, ip);
  }
}

Future<void> _startHttpServer(Handler handler, InternetAddress ip) async {
  final port = int.parse(Platform.environment['PORT'] ?? '8080');
  final server = await serve(handler, ip, port);
  print('🌐 HTTP Server listening on port ${server.port}');
} 