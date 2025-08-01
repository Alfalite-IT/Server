import 'dart:convert';
import 'package:shelf/shelf.dart';
import '../services/database_service.dart';
import '../validators/product_validator.dart';

class ProductHandlers {
  final DatabaseService _dbService;

  ProductHandlers(this._dbService);

  // Helper to convert a database row (snake_case) to a JSON map (camelCase)
  Map<String, dynamic> _productToJson(Map<String, dynamic> rowMap) {
    return {
          'id': rowMap['id'],
          'name': rowMap['name'],
          'location': rowMap['location'],
          'application': rowMap['application'],
          'horizontal': rowMap['horizontal'],
          'vertical': rowMap['vertical'],
          'pixelPitch': rowMap['pixel_pitch'],
          'width': rowMap['width'],
          'height': rowMap['height'],
          'depth': rowMap['depth'],
          'consumption': rowMap['consumption'],
          'weight': rowMap['weight'],
          'brightness': rowMap['brightness'],
          'image': rowMap['image'],
          'refreshRate': rowMap['refresh_rate'],
          'contrast': rowMap['contrast'],
          'visionAngle': rowMap['vision_angle'],
          'redundancy': rowMap['redundancy'],
          'curvedVersion': rowMap['curved_version'],
          'opticalMultilayerInjection': rowMap['optical_multilayer_injection'],
    };
      }

  Future<Response> productsHandler(Request request) async {
    try {
      final connection = await _dbService.openConnection(DbConnectionRole.public);
      final result = await connection.query('SELECT * FROM products ORDER BY id');
      final productsList = result.map((row) => _productToJson(row.toColumnMap())).toList();
      final jsonBody = jsonEncode(productsList);
      return Response.ok(jsonBody, headers: {'Content-Type': 'application/json'});
    } catch (e, s) {
      print('Exception: $e');
      print('Stack trace: $s');
      return Response.internalServerError(body: 'Failed to fetch products: ${e.toString()}');
    } finally {
      await _dbService.closeConnection();
    }
  }

  // A simple handler to test the database connection.
  Future<Response> dbTestHandler(Request request) async {
    try {
      final connection = await _dbService.openConnection(DbConnectionRole.public);
      final result = await connection.query('SELECT current_database();');
      final currentDbName = result.first.first as String;
      return Response.ok('Successfully connected to database: $currentDbName');
    } catch (e, s) {
      print('Exception: $e');
      print('Stack trace: $s');
      return Response.internalServerError(
          body: 'Database connection failed: ${e.toString()}');
    } finally {
      await _dbService.closeConnection();
    }
  }

  Future<Response> createProductHandler(Request request) async {
    try {
      final body = await request.readAsString();
      final productData = jsonDecode(body) as Map<String, dynamic>;
      
      // Validate the incoming data
      final validationError = ProductValidator(productData).validate();
      if (validationError != null) {
        return Response(400, body: jsonEncode({'error': validationError}));
      }

      final sql = '''
        INSERT INTO products (
          name, location, application, horizontal, vertical, pixel_pitch, 
          width, height, depth, consumption, weight, brightness, image, 
          refresh_rate, contrast, vision_angle, redundancy, curved_version, 
          optical_multilayer_injection
        ) VALUES (
          @name, @location, @application, @horizontal, @vertical, @pixelPitch,
          @width, @height, @depth, @consumption, @weight, @brightness, @image,
          @refreshRate, @contrast, @visionAngle, @redundancy, @curvedVersion,
          @opticalMultilayerInjection
        ) RETURNING *;
      ''';

      final connection = await _dbService.openConnection(DbConnectionRole.admin);
      final result = await connection.query(sql, substitutionValues: {
        'name': productData['name'],
        'location': productData['location'],
        'application': productData['application'],
        'horizontal': productData['horizontal'],
        'vertical': productData['vertical'],
        'pixelPitch': productData['pixelPitch'],
        'width': productData['width'],
        'height': productData['height'],
        'depth': productData['depth'],
        'consumption': productData['consumption'],
        'weight': productData['weight'],
        'brightness': productData['brightness'],
        'image': productData['image'],
        'refreshRate': productData['refreshRate'],
        'contrast': productData['contrast'],
        'visionAngle': productData['visionAngle'],
        'redundancy': productData['redundancy'],
        'curvedVersion': productData['curvedVersion'],
        'opticalMultilayerInjection': productData['opticalMultilayerInjection'],
      });

      final newProductMap = result.first.toColumnMap();
      return Response(201, body: jsonEncode(_productToJson(newProductMap)), headers: {'Content-Type': 'application/json'});

    } catch (e, s) {
      print('Exception: $e');
      print('Stack trace: $s');
      return Response.internalServerError(body: 'Failed to create product: $e');
    } finally {
      await _dbService.closeConnection();
    }
  }

  Future<Response> updateProductHandler(Request request, String id) async {
    try {
      final body = await request.readAsString();
      final productData = jsonDecode(body) as Map<String, dynamic>;
      
      // Validate the incoming data
      final validationError = ProductValidator(productData).validate();
      if (validationError != null) {
        return Response(400, body: jsonEncode({'error': validationError}));
      }
      
      final sql = '''
        UPDATE products SET
          name = @name,
          location = @location,
          application = @application,
          horizontal = @horizontal,
          vertical = @vertical,
          pixel_pitch = @pixelPitch,
          width = @width,
          height = @height,
          depth = @depth,
          consumption = @consumption,
          weight = @weight,
          brightness = @brightness,
          image = @image,
          refresh_rate = @refreshRate,
          contrast = @contrast,
          vision_angle = @visionAngle,
          redundancy = @redundancy,
          curved_version = @curvedVersion,
          optical_multilayer_injection = @opticalMultilayerInjection
        WHERE id = @id
        RETURNING *;
      ''';

      final connection = await _dbService.openConnection(DbConnectionRole.admin);
      final result = await connection.query(sql, substitutionValues: {
        'id': int.parse(id),
        'name': productData['name'],
        'location': productData['location'],
        'application': productData['application'],
        'horizontal': productData['horizontal'],
        'vertical': productData['vertical'],
        'pixelPitch': productData['pixelPitch'],
        'width': productData['width'],
        'height': productData['height'],
        'depth': productData['depth'],
        'consumption': productData['consumption'],
        'weight': productData['weight'],
        'brightness': productData['brightness'],
        'image': productData['image'],
        'refreshRate': productData['refreshRate'],
        'contrast': productData['contrast'],
        'visionAngle': productData['visionAngle'],
        'redundancy': productData['redundancy'],
        'curvedVersion': productData['curvedVersion'],
        'opticalMultilayerInjection': productData['opticalMultilayerInjection'],
      });

      final updatedProductMap = result.first.toColumnMap();
      return Response.ok(jsonEncode(_productToJson(updatedProductMap)), headers: {'Content-Type': 'application/json'});

    } catch (e, s) {
      print('Exception: $e');
      print('Stack trace: $s');
      return Response.internalServerError(body: 'Failed to update product: $e');
    } finally {
      await _dbService.closeConnection();
    }
  }

  Future<Response> deleteProductHandler(Request request, String id) async {
    try {
      final connection = await _dbService.openConnection(DbConnectionRole.admin);
      await connection.execute('DELETE FROM products WHERE id = @id', substitutionValues: {'id': int.parse(id)});
      return Response(204); // No Content is more appropriate for a successful DELETE
    } catch (e, s) {
      print('Exception: $e');
      print('Stack trace: $s');
      return Response.internalServerError(body: 'Failed to delete product: $e');
    } finally {
      await _dbService.closeConnection();
    }
  }
} 