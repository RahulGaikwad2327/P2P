// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
// file_download_web.dart — Web browser Blob download implementation
import 'dart:html' as html;

void downloadFileBytes(List<int> bytes, String fileName) {
  final blob = html.Blob([bytes]);
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.AnchorElement(href: url)
    ..setAttribute('download', fileName)
    ..click();
  html.Url.revokeObjectUrl(url);
}
