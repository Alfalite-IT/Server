import 'dart:typed_data';
import 'dart:async';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'config_service.dart';

class EmailService {
  final ConfigService _configService;

  EmailService(this._configService);

  Future<bool> sendPdfEmail({
    required String userEmail,
    required String userName,
    required String companyName,
    required String projectName,
    required Uint8List pdfBytes,
    required String pdfFileName,
    required String emailType, // 'pdf', 'quote', 'comparison'
  }) async {
    try {
      // Create SMTP server configuration
      final smtpServer = SmtpServer(
        _configService.smtpHost,
        port: _configService.smtpPort,
        username: _configService.smtpUsername,
        password: _configService.smtpPassword,
        ssl: _configService.smtpPort == 465, // Use SSL for port 465
        allowInsecure: false, // Require secure connection for production
      );

      // Determine email subject and content based on type
      String subject;
      String emailContent;
      
      switch (emailType) {
        case 'pdf':
          subject = 'Alfalite Configuration - PDF Document';
          emailContent = _generatePdfEmailContent(userName, companyName, projectName);
          break;
        case 'quote':
          subject = 'Alfalite Configuration - Quote Request';
          emailContent = _generateQuoteEmailContent(userName, companyName, projectName);
          break;
        case 'comparison':
          subject = 'Alfalite Configuration - Product Comparison';
          emailContent = _generateComparisonEmailContent(userName, companyName, projectName);
          break;
        default:
          subject = 'Alfalite Configuration Document';
          emailContent = _generatePdfEmailContent(userName, companyName, projectName);
      }

      // Create the email message
      final message = Message()
        ..from = Address(_configService.companyEmail, 'Alfalite Configurator')
        ..recipients.add(userEmail)
        ..ccRecipients.add(_configService.companyEmail) // Send copy to internal tracking
        ..subject = subject
        ..html = emailContent
        ..attachments = [
          StreamAttachment(
            Stream.value(pdfBytes),
            'application/pdf',
            fileName: pdfFileName,
          ),
        ];

      // Send the email
      final sendReport = await send(message, smtpServer);
      
      print('Email sent successfully: ${sendReport.toString()}');
      return true;
    } catch (e) {
      print('Failed to send email: $e');
      return false;
    }
  }

  String _generatePdfEmailContent(String userName, String companyName, String projectName) {
    return '''
    <!DOCTYPE html>
    <html>
    <head>
        <meta charset="utf-8">
        <style>
            body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
            .header { background-color: #FC7100; color: white; padding: 20px; text-align: center; }
            .content { padding: 20px; }
            .footer { background-color: #f4f4f4; padding: 15px; text-align: center; font-size: 12px; }
        </style>
    </head>
    <body>
        <div class="header">
            <h1>Alfalite Configuration</h1>
        </div>
        <div class="content">
            <p>Dear $userName,</p>
            <p>Thank you for using the Alfalite Configurator. Please find attached your configuration document.</p>
            <p><strong>Project Details:</strong></p>
            <ul>
                <li><strong>Project Name:</strong> $projectName</li>
                <li><strong>Company:</strong> $companyName</li>
            </ul>
            <p>If you have any questions about your configuration or would like to discuss your project further, please don't hesitate to contact us.</p>
            <p>Best regards,<br>The Alfalite Team</p>
        </div>
        <div class="footer">
            <p>This email was sent from the Alfalite Configurator system.</p>
        </div>
    </body>
    </html>
    ''';
  }

  String _generateQuoteEmailContent(String userName, String companyName, String projectName) {
    return '''
    <!DOCTYPE html>
    <html>
    <head>
        <meta charset="utf-8">
        <style>
            body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
            .header { background-color: #FC7100; color: white; padding: 20px; text-align: center; }
            .content { padding: 20px; }
            .footer { background-color: #f4f4f4; padding: 15px; text-align: center; font-size: 12px; }
        </style>
    </head>
    <body>
        <div class="header">
            <h1>Alfalite Quote Request</h1>
        </div>
        <div class="content">
            <p>Dear $userName,</p>
            <p>Thank you for your quote request. We have received your configuration and will review it with our technical team.</p>
            <p><strong>Project Details:</strong></p>
            <ul>
                <li><strong>Project Name:</strong> $projectName</li>
                <li><strong>Company:</strong> $companyName</li>
            </ul>
            <p>Our sales team will contact you within 24-48 hours with a detailed quote and technical specifications.</p>
            <p>If you have any urgent questions, please contact us directly.</p>
            <p>Best regards,<br>The Alfalite Sales Team</p>
        </div>
        <div class="footer">
            <p>This quote request was submitted through the Alfalite Configurator system.</p>
        </div>
    </body>
    </html>
    ''';
  }

  String _generateComparisonEmailContent(String userName, String companyName, String projectName) {
    return '''
    <!DOCTYPE html>
    <html>
    <head>
        <meta charset="utf-8">
        <style>
            body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
            .header { background-color: #FC7100; color: white; padding: 20px; text-align: center; }
            .content { padding: 20px; }
            .footer { background-color: #f4f4f4; padding: 15px; text-align: center; font-size: 12px; }
        </style>
    </head>
    <body>
        <div class="header">
            <h1>Alfalite Product Comparison</h1>
        </div>
        <div class="content">
            <p>Dear $userName,</p>
            <p>Thank you for using our comparison tool. Please find attached a detailed comparison of the selected products.</p>
            <p><strong>Project Details:</strong></p>
            <ul>
                <li><strong>Project Name:</strong> $projectName</li>
                <li><strong>Company:</strong> $companyName</li>
            </ul>
            <p>This comparison will help you make an informed decision about your display solution. If you need any clarification or have questions about the differences between the products, please contact our technical team.</p>
            <p>Best regards,<br>The Alfalite Technical Team</p>
        </div>
        <div class="footer">
            <p>This comparison was generated through the Alfalite Configurator system.</p>
        </div>
    </body>
    </html>
    ''';
  }
} 