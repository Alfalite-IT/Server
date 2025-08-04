import 'dart:convert';
import 'package:shelf/shelf.dart';
import '../services/email_service.dart';
import '../services/config_service.dart';
import '../services/rate_limiter_service.dart';

class EmailHandlers {
  final EmailService _emailService;
  final RateLimiterService _rateLimiter;

  EmailHandlers(ConfigService configService) 
      : _emailService = EmailService(configService),
        _rateLimiter = RateLimiterService(
          maxRequests: configService.emailRateLimit,
          window: const Duration(hours: 1),
        );

  Future<Response> sendPdfEmailHandler(Request request) async {
    try {
      // Get client IP for rate limiting
      final clientIp = request.headers['x-forwarded-for'] ?? 
                      request.headers['x-real-ip'] ?? 
                      'unknown';
      
      // Check rate limiting
      if (!_rateLimiter.isAllowed(clientIp)) {
        return Response(429, // Too Many Requests
          body: jsonEncode({
            'success': false,
            'message': 'Rate limit exceeded. Please try again later.',
            'remainingRequests': 0,
          }),
          headers: {'content-type': 'application/json'},
        );
      }

      // Check request size
      final contentLength = int.tryParse(request.headers['content-length'] ?? '0') ?? 0;
      if (contentLength > 10485760) { // 10MB limit
        return Response(413, // Payload Too Large
          body: jsonEncode({
            'success': false,
            'message': 'Request too large. Maximum size is 10MB.',
          }),
          headers: {'content-type': 'application/json'},
        );
      }

      // Parse request data
      final formData = await request.readAsString();
      final body = jsonDecode(formData);
      
      // Extract and validate data from request
      final userData = body['userData'];
      final pdfBytes = base64Decode(body['pdfBytes']);
      final emailType = body['emailType'] ?? 'pdf';
      
      // Validate user email
      final userEmail = userData['email']?.toString() ?? '';
      if (userEmail.isEmpty || !_isValidEmail(userEmail)) {
        return Response(400,
          body: jsonEncode({
            'success': false,
            'message': 'Invalid email address provided.',
          }),
          headers: {'content-type': 'application/json'},
        );
      }
      
      // Generate filename based on type
      String fileName;
      switch (emailType) {
        case 'quote':
          fileName = 'Alfalite_Quote_${userData['projectName']?.replaceAll(' ', '_') ?? 'Request'}.pdf';
          break;
        case 'comparison':
          fileName = 'Alfalite_Comparison_${userData['projectName']?.replaceAll(' ', '_') ?? 'Chart'}.pdf';
          break;
        default:
          fileName = 'Alfalite_Configuration_${userData['projectName']?.replaceAll(' ', '_') ?? 'Document'}.pdf';
      }

      // Send email
      final success = await _emailService.sendPdfEmail(
        userEmail: userData['email'],
        userName: '${userData['firstName']} ${userData['lastName']}',
        companyName: userData['company'],
        projectName: userData['projectName'],
        pdfBytes: pdfBytes,
        pdfFileName: fileName,
        emailType: emailType,
      );

      if (success) {
        return Response.ok(
          jsonEncode({
            'success': true,
            'message': 'Email sent successfully',
            'type': emailType,
          }),
          headers: {'content-type': 'application/json'},
        );
      } else {
        return Response.internalServerError(
          body: jsonEncode({
            'success': false,
            'message': 'Failed to send email',
            'type': emailType,
          }),
          headers: {'content-type': 'application/json'},
        );
      }
    } catch (e) {
      print('Error in sendPdfEmailHandler: $e');
      return Response.internalServerError(
        body: jsonEncode({
          'success': false,
          'message': 'Internal server error: ${e.toString()}',
        }),
        headers: {'content-type': 'application/json'},
      );
    }
  }

  Future<Response> sendQuoteEmailHandler(Request request) async {
    // Redirect to the general PDF email handler with quote type
    final body = await request.readAsString();
    final data = jsonDecode(body);
    data['emailType'] = 'quote';
    
    final modifiedRequest = request.change(body: jsonEncode(data));
    return sendPdfEmailHandler(modifiedRequest);
  }

  Future<Response> sendComparisonEmailHandler(Request request) async {
    // Redirect to the general PDF email handler with comparison type
    final body = await request.readAsString();
    final data = jsonDecode(body);
    data['emailType'] = 'comparison';
    
    final modifiedRequest = request.change(body: jsonEncode(data));
    return sendPdfEmailHandler(modifiedRequest);
  }

  bool _isValidEmail(String email) {
    // Basic email validation regex
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    return emailRegex.hasMatch(email);
  }
} 