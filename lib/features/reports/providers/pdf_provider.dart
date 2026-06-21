import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/pdf_service.dart';

final pdfServiceProvider = Provider<PdfService>((ref) {
  return PdfService();
});
