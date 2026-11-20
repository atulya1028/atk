import 'package:flutter/foundation.dart';
import 'csv_exporter_stub.dart' if (dart.library.html) 'csv_exporter_web.dart';

class CsvExporter {
  CsvExporter._();

  static void export({required String filename, required String content}) {
    if (kIsWeb) {
      downloadCsvWeb(filename, content);
    }
  }
}
