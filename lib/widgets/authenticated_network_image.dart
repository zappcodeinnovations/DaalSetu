import 'package:daalsetu/comman/api_url.dart';
import 'package:daalsetu/utils/app_preferences.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class AuthenticatedNetworkImage extends StatefulWidget {
  const AuthenticatedNetworkImage({
    super.key,
    required this.url,
    this.height,
    this.width,
    this.fit = BoxFit.cover,
    required this.fallback,
  });

  final String url;
  final double? height;
  final double? width;
  final BoxFit fit;
  final Widget fallback;

  @override
  State<AuthenticatedNetworkImage> createState() =>
      _AuthenticatedNetworkImageState();
}

class _AuthenticatedNetworkImageState extends State<AuthenticatedNetworkImage> {
  late final Future<String?> _token;

  @override
  void initState() {
    super.initState();
    _token = AppPreferences.getAccessToken();
  }

  String _formatUrl(String url) {
    String clean = url.trim();
    if (clean.isEmpty) return "";
    if (!clean.startsWith("http://") && !clean.startsWith("https://")) {
      if (!clean.startsWith("/")) clean = "/$clean";
      clean = "${ApiUrls.baseUrl}$clean";
    }
    return clean;
  }

  @override
  Widget build(BuildContext context) {
    final formattedUrl = _formatUrl(widget.url);
    if (formattedUrl.isEmpty) {
      return widget.fallback;
    }

    return FutureBuilder<String?>(
      future: _token,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return SizedBox(
            height: widget.height,
            width: widget.width,
            child: const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        }

        final token = snapshot.data;
        return FutureBuilder<http.Response>(
          future: http.get(
            Uri.parse(formattedUrl),
            headers: token == null || token.isEmpty
                ? const {}
                : {'Authorization': 'Bearer $token'},
          ).catchError((_) => http.Response('', 500)),
          builder: (context, responseSnapshot) {
            if (responseSnapshot.connectionState != ConnectionState.done) {
              return SizedBox(
                height: widget.height,
                width: widget.width,
                child: const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              );
            }

            if (responseSnapshot.hasError ||
                responseSnapshot.data == null ||
                responseSnapshot.data!.statusCode != 200) {
              return widget.fallback;
            }

            return Image.memory(
              responseSnapshot.data!.bodyBytes,
              height: widget.height,
              width: widget.width,
              fit: widget.fit,
              errorBuilder: (context, error, stackTrace) => widget.fallback,
            );
          },
        );
      },
    );
  }
}
