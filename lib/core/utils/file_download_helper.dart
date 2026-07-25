// file_download_helper.dart — Conditional import facade for Web & Native file downloads

export 'file_download_stub.dart'
    if (dart.library.html) 'file_download_web.dart';
