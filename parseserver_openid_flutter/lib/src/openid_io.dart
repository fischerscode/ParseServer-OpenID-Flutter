import 'package:flutter/services.dart';
import 'package:parseserver_openid_flutter/parseserver_openid_flutter.dart';
import 'package:uni_links/uni_links.dart';
import 'package:url_launcher/url_launcher.dart';

ParseOpenID createOpenID() {
  return IOParseOpenID.internal();
}

class IOParseOpenID extends ParseOpenID {
  IOParseOpenID.internal() : super.internal();

  @override
  Future<Uri> authorize(
    Uri authorizationUrl,
    StateSetter stateSetter,
  ) async {
    if (await canLaunch(authorizationUrl.toString())) {
      launch(authorizationUrl.toString(), forceWebView: false)
          .onError((error, stackTrace) async {
        if (error is PlatformException) return;
        throw error;
      });

      Uri redirectedUrl = await getLinksStream()
          .firstWhere((e) => e.contains("session_state="))
          .then((value) => Uri.parse(value));
      closeWebView();
      return redirectedUrl;
    } else {
      throw 'Could not launch $authorizationUrl';
    }
  }

  @override
  Uri createRedirectUrl() {
    return Uri(
      host: redirectHost,
      scheme: redirectScheme,
      path: redirectPath,
    );
  }
}
