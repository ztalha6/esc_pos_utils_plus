export 'platform_service_none.dart'
    if (dart.library.ffi) 'platform_service_io.dart'
    if (dart.library.html) 'platform_service_web.dart';
