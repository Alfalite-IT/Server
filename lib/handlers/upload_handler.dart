import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf_multipart/shelf_multipart.dart';
import 'package:path/path.dart' as p;

class UploadHandler {
  final String _uploadDirectory;

  UploadHandler({String uploadDirectory = 'public/images'})
      : _uploadDirectory = uploadDirectory;

  Future<Response> uploadImage(Request request) async {
    // request.formData() returns a FormDataRequest? object.
    final formDataRequest = request.formData();

    // Check if the request is valid multipart form-data.
    if (formDataRequest == null) {
      return Response(400,
          body: 'Invalid request: not a multipart/form-data request.');
    }

    try {
      String? filePath;
      // Iterate over the .formData stream within the FormDataRequest object.
      await for (final formData in formDataRequest.formData) {
        if (formData.name == 'image') {
          final part = formData.part;
          final headers = part.headers;
          final contentType = headers['content-type'];

          if (contentType == null ||
              !['image/jpeg', 'image/png', 'image/gif']
                  .contains(contentType.split(';').first)) {
            return Response(400,
                body:
                    'Invalid file type. Only JPEG, PNG, and GIF are allowed.');
          }

          final fileBytes = await part.readBytes();
          final timestamp = DateTime.now().millisecondsSinceEpoch;
          final originalFilename = formData.filename;
          final extension =
              originalFilename != null ? p.extension(originalFilename) : '.jpg';
          final uniqueFilename =
              '${timestamp}_${p.basenameWithoutExtension(originalFilename ?? 'upload')}$extension';

          final fullPath = p.join(_uploadDirectory, uniqueFilename);
          final file = File(fullPath);

          await file.create(recursive: true);
          await file.writeAsBytes(fileBytes);

          filePath = '/images/$uniqueFilename';
          break; // Exit after processing the first image file.
        }
      }

      if (filePath != null) {
        return Response.ok('{"imageUrl": "$filePath"}',
            headers: {'Content-Type': 'application/json'});
      } else {
        return Response(400, body: 'No "image" field found in the request.');
      }
    } catch (e) {
      print('Image upload error: $e');
      return Response.internalServerError(
          body: 'An error occurred during file upload.');
    }
  }
}