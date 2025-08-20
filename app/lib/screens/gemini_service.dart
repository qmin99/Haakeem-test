import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:http/http.dart' as http;

import '../constants/enums.dart';
import '../models/file_models.dart';





class GeminiService {
  static const String _apiKey = 'AIzaSyCUZwFxRupjPAghX63nDUCfWctetOu-Twg';

  Future<String> sendMessage({
    required String message,
    List<AttachedFile> attachedFiles = const [],
    LegalLevel legalLevel = LegalLevel.beginner,
    List<Map<String, String>> conversationHistory = const [],
  }) async {
    try {
      final gemini = Gemini.instance;
      String systemPrompt = _buildSystemPrompt(legalLevel);

      String fullPrompt;
      if (conversationHistory.isNotEmpty) {
        String historyContext = _buildHistoryContext(conversationHistory);
        fullPrompt = '$systemPrompt\n\n$historyContext\n\nUser: $message';
      } else {
        fullPrompt = '$systemPrompt\n\nUser: $message';
      }

      for (var file in attachedFiles) {
        if (file.prompt != null && file.prompt!.isNotEmpty) {
          fullPrompt += '\n\nInstructions for ${file.name}: ${file.prompt}';
        }
      }

      String? response;

      if (attachedFiles.isNotEmpty) {
        // Process files by priority: PDFs first (special handling), then images, then other documents
        final pdfFiles = attachedFiles.where((file) => file.isPdf).toList();
        final imageFiles = attachedFiles.where((file) => file.isImage).toList();
        final documentFiles = attachedFiles.where((file) => file.isDocument).toList();
        final otherFiles = attachedFiles.where((file) => !file.isPdf && !file.isImage && !file.isDocument).toList();

        // Handle PDFs first (they have special processing)
        if (pdfFiles.isNotEmpty) {
          response = await _handlePdfFiles(fullPrompt, pdfFiles);
        } 
        // Handle images (can be processed directly with vision API)
        else if (imageFiles.isNotEmpty) {
          List<Uint8List> images = imageFiles.map((file) => file.data).toList();
          final result = await gemini.textAndImage(
            text: fullPrompt,
            images: images,
          );
          response = result?.output;
        } 
        // Handle document files (doc, docx, txt, etc.)
        else if (documentFiles.isNotEmpty) {
          // Add note about document analysis
          fullPrompt += '\n\nNote: Please analyze the document content I have described or provided.';
          final result = await gemini.text(fullPrompt);
          response = result?.output;
        }
        // Handle any other file types that weren't caught above
        else if (otherFiles.isNotEmpty) {
          fullPrompt += '\n\nNote: Please analyze the file content based on the information provided.';
          final result = await gemini.text(fullPrompt);
          response = result?.output;
        }
        // Fallback - shouldn't happen but just in case
        else {
          final result = await gemini.text(fullPrompt);
          response = result?.output;
        }
      } else {
        final result = await gemini.text(fullPrompt);
        response = result?.output;
      }

      if (response != null && response.isNotEmpty) {
        return _formatResponse(response.trim());
      }

      return 'I apologize, but I was unable to generate a response. Please try rephrasing your question.';
    } catch (e) {
      return _handleGeminiError(e);
    }
  }

  Future<String> _handlePdfFiles(String prompt, List<AttachedFile> pdfFiles) async {
    try {
      final pdfFile = pdfFiles.first;
      final base64Data = base64Encode(pdfFile.data);
      
      final response = await _sendDirectApiRequest(prompt, base64Data);
      return response;
    } catch (e) {
      return '''🚫 **PDF Processing Error**

The PDF file couldn't be processed directly. Here are some options:

**Option 1: Convert to Images**
• Convert your PDF pages to JPG/PNG images
• Upload the images instead of the PDF

**Option 2: Extract Text**
• Copy and paste the text content from your PDF
• Send as a regular text message

**Option 3: Try a Smaller PDF**
• PDFs under 5MB work better
• Split large PDFs into smaller sections

**Technical Details:** ${e.toString()}''';
    }
  }

  Future<String> _sendDirectApiRequest(String prompt, String base64PdfData) async {
    try {
      final url = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$_apiKey';
      
      final requestBody = {
        'contents': [
          {
            'parts': [
              {
                'text': prompt
              },
              {
                'inline_data': {
                  'mime_type': 'application/pdf',
                  'data': base64PdfData
                }
              }
            ]
          }
        ],
        'generationConfig': {
          'temperature': 0.7,
          'topP': 0.8,
          'topK': 40,
          'maxOutputTokens': 2048,
        }
      };

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['candidates'] != null && 
            jsonResponse['candidates'].isNotEmpty &&
            jsonResponse['candidates'][0]['content'] != null &&
            jsonResponse['candidates'][0]['content']['parts'] != null &&
            jsonResponse['candidates'][0]['content']['parts'].isNotEmpty) {
          return jsonResponse['candidates'][0]['content']['parts'][0]['text'] ?? 'No response generated.';
        }
      } else {
        final errorResponse = jsonDecode(response.body);
        throw Exception('API Error: ${errorResponse['error']['message'] ?? 'Unknown error'}');
      }
    } catch (e) {
      throw Exception('Failed to process PDF: $e');
    }
    
    return 'Unable to process PDF file.';
  }

  String _handleGeminiError(dynamic error) {
    final errorString = error.toString().toLowerCase();
    
    if (errorString.contains('quota') || 
        errorString.contains('429') || 
        errorString.contains('rate limit')) {
      return '''🚫 **API Rate Limit Exceeded**

The Gemini API has reached its rate limit. Please try again in a few moments.

**What you can do:**
• Wait a few minutes before trying again
• Try with a shorter message
• Upload fewer files at once''';
    }
    
    if (errorString.contains('billing') || 
        errorString.contains('payment') || 
        errorString.contains('disabled')) {
      return '''🚫 **API Billing Issue**

There's an issue with the Gemini API billing configuration.

**Contact your administrator to:**
• Check API billing status
• Verify payment methods
• Enable the Gemini API service''';
    }
    
    if (errorString.contains('pdf') || 
        errorString.contains('application/pdf') ||
        errorString.contains('mime type')) {
      return '''🚫 **PDF Processing Error**

PDFs require special handling with the Gemini API.

**Recommended solutions:**
• Convert PDF pages to images (JPG/PNG) and upload those
• Extract text from the PDF and send as text message
• Try a smaller PDF file (under 5MB)
• Use a different document format like Word or plain text

**Why this happens:** The flutter_gemini package has limited PDF support compared to images.''';
    }
    
    if (errorString.contains('file') || 
        errorString.contains('upload') || 
        errorString.contains('size')) {
      return '''🚫 **File Processing Error**

The uploaded file couldn't be processed by Gemini AI.

**Possible solutions:**
• Try with a smaller file (under 20MB)
• Convert PDF to images if it's a scanned document
• Use a different file format (JPG, PNG for images)
• Ensure the file isn't corrupted''';
    }
    
    if (errorString.contains('network') || 
        errorString.contains('connection') || 
        errorString.contains('timeout')) {
      return '''🚫 **Network Error**

Unable to connect to Gemini AI services.

**Please check:**
• Your internet connection
• Try again in a moment
• Contact support if the issue persists''';
    }

    return '''🚫 **Processing Error**

Unable to process your request at this time.

**Error details:** ${error.toString()}

**Suggested actions:**
• For PDFs: Convert to images (JPG/PNG) and re-upload
• For documents: Copy and paste the text content instead
• Try refreshing the page
• Contact support if the issue continues

**Tip:** Images work perfectly with our AI system!''';
  }

  String _formatResponse(String response) {
    String formatted = response;
    
    formatted = formatted.replaceAllMapped(
      RegExp(r'\*\*(.*?)\*\*'),
      (match) => '**${match.group(1)}**',
    );
    
    formatted = formatted.replaceAllMapped(
      RegExp(r'\*(.*?)\*'),
      (match) => '*${match.group(1)}*',
    );
    
    formatted = formatted.replaceAllMapped(
      RegExp(r'^-\s+(.*)$', multiLine: true),
      (match) => '• ${match.group(1)}',
    );
    
    formatted = formatted.replaceAllMapped(
      RegExp(r'^\*\s+(.*)$', multiLine: true),
      (match) => '• ${match.group(1)}',
    );
    
    formatted = formatted.replaceAllMapped(
      RegExp(r'^(\d+)\.\s+(.*)$', multiLine: true),
      (match) => '${match.group(1)}. ${match.group(2)}',
    );
    
    formatted = formatted.replaceAllMapped(
      RegExp(r'```(\w*)\n(.*?)```', dotAll: true),
      (match) => '```${match.group(1)}\n${match.group(2)}```',
    );
    
    formatted = formatted.replaceAllMapped(
      RegExp(r'`([^`]+)`'),
      (match) => '`${match.group(1)}`',
    );
    
    formatted = formatted.replaceAllMapped(
      RegExp(r'#{1,6}\s+(.*)$', multiLine: true),
      (match) => '**${match.group(1)}**',
    );
    
    formatted = formatted.replaceAll(RegExp(r'\n{3,}'), '\n\n');
    
    formatted = formatted.trim();
    
    return formatted;
  }

  Future<String> analyzeDocument({
    required AttachedFile file,
    String? customPrompt,
    LegalLevel legalLevel = LegalLevel.beginner,
  }) async {
    String prompt;
    
    if (customPrompt != null && customPrompt.isNotEmpty) {
      prompt = customPrompt;
    } else {
      prompt = _getDefaultAnalysisPrompt(file.name);
    }

    if (file.isPdf) {
      prompt += '\n\nNote: This is a PDF document. Please extract and analyze all visible text content.';
    }

    return sendMessage(
      message: prompt,
      attachedFiles: [file],
      legalLevel: legalLevel,
    );
  }

  Future<String> summarizeDocument({
    required AttachedFile file,
    LegalLevel legalLevel = LegalLevel.beginner,
  }) async {
    final prompt = legalLevel == LegalLevel.beginner
        ? "Please provide a clear, easy-to-understand summary of this document. Break down the main points and explain any legal terms in simple language."
        : "Provide a comprehensive legal summary of this document, including key clauses, legal implications, and relevant statutory references.";

    return analyzeDocument(
      file: file,
      customPrompt: prompt,
      legalLevel: legalLevel,
    );
  }

  Future<String> extractKeyPoints({
    required AttachedFile file,
    LegalLevel legalLevel = LegalLevel.beginner,
  }) async {
    const prompt =
        "Extract and list the key points, important clauses, and critical information from this document. Present them in a clear, organized format with bullet points.";

    return analyzeDocument(
      file: file,
      customPrompt: prompt,
      legalLevel: legalLevel,
    );
  }

  Future<String> performLegalAnalysis({
    required AttachedFile file,
    LegalLevel legalLevel = LegalLevel.beginner,
  }) async {
    final prompt = legalLevel == LegalLevel.beginner
        ? "Analyze this document from a legal perspective. Explain any potential legal issues, rights, obligations, and important considerations in simple terms."
        : "Perform a detailed legal analysis of this document, including statutory compliance, contractual obligations, potential risks, and recommended actions.";

    return analyzeDocument(
      file: file,
      customPrompt: prompt,
      legalLevel: legalLevel,
    );
  }

  String _buildSystemPrompt(LegalLevel legalLevel) {
    String basePrompt =
        '''You are an AI Legal Assistant specialized in providing helpful, accurate legal information and guidance. Your role is to assist users with legal questions, document analysis, and legal research.

Key Guidelines:
- Provide accurate, helpful legal information based on general legal principles
- Be thorough in your analysis and explanations
- Focus on practical, actionable guidance
- Maintain professional tone while being approachable
- When analyzing documents, be specific about what you find
- Cite relevant sections or clauses when discussing document content
- Format your responses clearly with proper markdown formatting
- Use bullet points for lists and important points
- Bold important terms and headers
- Structure your response logically with clear sections''';

    if (legalLevel == LegalLevel.beginner) {
      basePrompt += '''

User Experience Level: BEGINNER
- Explain legal concepts in simple, easy-to-understand language
- Avoid excessive legal jargon, or explain it when necessary
- Provide practical examples and analogies
- Break down complex topics into digestible parts
- Include helpful context and background information
- Use bullet points and clear formatting for better readability
- Define legal terms when you use them''';
    } else {
      basePrompt += '''

User Experience Level: EXPERT
- Use appropriate legal terminology and technical language
- Provide detailed analysis with citations when relevant
- Include nuanced legal considerations and edge cases
- Reference relevant laws, regulations, and legal precedents when applicable
- Assume familiarity with basic legal concepts
- Provide comprehensive analysis with multiple perspectives''';
    }

    basePrompt += '''

When analyzing documents:
- Be specific about what you find in the document
- Quote relevant sections when discussing specific clauses
- Highlight potential issues or areas of concern
- Suggest questions the user might want to ask a lawyer
- For PDFs, extract and analyze all visible text content
- For images, describe what you see and extract any visible text

Formatting Requirements:
- Use **bold** for important terms and headers
- Use bullet points (•) for lists
- Use numbered lists for step-by-step processes
- Use `code formatting` for specific legal terms or clauses
- Structure responses with clear sections and spacing''';

    return basePrompt;
  }

  String _buildHistoryContext(List<Map<String, String>> conversationHistory) {
    if (conversationHistory.isEmpty) return '';

    final contextLines = <String>[];
    contextLines.add('Previous conversation context:');

    for (final exchange in conversationHistory.take(5)) {
      if (exchange['user'] != null) {
        contextLines.add('User: ${exchange['user']}');
      }
      if (exchange['assistant'] != null) {
        contextLines.add('Assistant: ${exchange['assistant']}');
      }
    }

    return contextLines.join('\n');
  }

  String _getDefaultAnalysisPrompt(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();

    switch (extension) {
      case 'pdf':
        return '''Please analyze this PDF document thoroughly. I need you to:

• Extract and analyze all visible text content
• Provide a comprehensive overview of the document structure
• Identify key terms, clauses, and important legal considerations
• Summarize the main points in an organized manner

Note: This is a PDF file that may contain formatted text, tables, or multiple pages.''';
      case 'doc':
      case 'docx':
        return 'Please analyze this document and provide a comprehensive overview of its contents, key terms, and any important legal considerations.';
      case 'txt':
        return 'Please analyze this text document and provide insights into its legal content and implications.';
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'webp':
      case 'bmp':
        return 'Please analyze this image and extract any text or legal information visible in it. Describe what you see and provide relevant legal insights.';
      default:
        return 'Please analyze this file and provide relevant legal insights based on its contents.';
    }
  }

  List<String> getSupportedFileTypes() {
    return ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp', 'txt'];
  }

  List<String> getPartiallySupported() {
    return ['pdf', 'doc', 'docx'];
  }

  bool isFileTypeSupported(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    return getSupportedFileTypes().contains(extension);
  }

  bool isFileTypePartiallySupported(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    return getPartiallySupported().contains(extension);
  }

  int getMaxFileSize() {
    return 20 * 1024 * 1024;
  }

  bool isFileSizeValid(int fileSizeInBytes) {
    return fileSizeInBytes <= getMaxFileSize();
  }

  String getFileSizeErrorMessage() {
    return 'File size must be less than ${getMaxFileSize() / (1024 * 1024)}MB';
  }

  String getUnsupportedFileTypeMessage(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    final supported = getSupportedFileTypes().join(', ');
    final partiallySupported = getPartiallySupported().join(', ');
    
    if (getPartiallySupported().contains(extension)) {
      return '''File type "$extension" has limited support. 

**For best results:**
• Convert PDF to images (JPG/PNG)
• Copy text from Word docs and paste as text
• Use image formats: $supported

**Partially supported:** $partiallySupported''';
    }
    
    return 'File type "$extension" is not supported. Supported types: $supported';
  }
}

class GeminiException implements Exception {
  final String message;

  GeminiException(this.message);

  @override
  String toString() => 'GeminiException: $message';
}