import 'package:daalsetu/comman/api_url.dart';

/// Points backend media links at the app's own HTTPS origin.
///
/// The backend builds absolute URLs from the incoming request, so behind a proxy they
/// can come back as `http://` (blocked on Android) or relative. App-owned paths
/// (`/api/...`, `/media/...`) are always served from [ApiUrls.baseUrl].
Uri resolveMediaUri(String url) {
  final base = Uri.parse(ApiUrls.baseUrl);
  final parsed = Uri.tryParse(url.trim());
  if (parsed == null) return Uri.parse(url);
  if (!parsed.hasScheme) return base.resolveUri(parsed);
  if (parsed.path.startsWith('/api/') || parsed.path.startsWith('/media/')) {
    return base.replace(path: parsed.path, query: parsed.hasQuery ? parsed.query : null);
  }
  return parsed;
}
