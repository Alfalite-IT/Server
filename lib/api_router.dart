import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'handlers/auth_handlers.dart';
import 'handlers/product_handlers.dart';
import 'handlers/static_handlers.dart';
import 'handlers/upload_handler.dart';
import 'middleware/auth_middleware.dart';
import 'services/auth_service.dart';
import 'services/config_service.dart';
import 'services/database_service.dart';
import 'services/jwt_service.dart';

class ApiRouter {
  final DatabaseService _dbService;
  final ConfigService _configService;

  ApiRouter(this._dbService, this._configService);

  Router get router {
    final router = Router();

    // Initialize services
    final jwtService = JwtService(_configService);
    final authService = AuthService(_dbService);
    
    // Initialize handlers
    final staticHandlers = StaticHandlers();
    final productHandlers = ProductHandlers(_dbService);
    final authHandlers = AuthHandlers(authService, jwtService);
    final uploadHandler = UploadHandler();

    // ======== Public Routes ========
    router.get('/', staticHandlers.rootHandler);
    router.get('/echo/<message>', staticHandlers.echoHandler);
    router.get('/products', productHandlers.productsHandler);
    router.get('/test_db', productHandlers.dbTestHandler);
    router.post('/login', authHandlers.loginHandler);

    // ======== Protected Routes ========
    final protectedRoutes = Router()
      ..post('/products', productHandlers.createProductHandler)
      ..put('/products/<id>', productHandlers.updateProductHandler)
      ..delete('/products/<id>', productHandlers.deleteProductHandler)
      ..post('/upload/image', uploadHandler.uploadImage);

    // Create a pipeline with the auth middleware
    final protectedPipeline = const Pipeline()
        .addMiddleware(createAuthMiddleware(jwtService))
        .addHandler(protectedRoutes);

    // Mount the protected routes under the pipeline
    router.mount('/', protectedPipeline);

    return router;
  }
} 