import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:oauth2/oauth2.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk.dart';
import 'package:parseserver_openid_flutter/parseserver_openid_flutter.dart';
import 'package:uni_links/uni_links.dart';
import 'package:url_launcher/url_launcher.dart';

ParseOpenID createOpenID({
  @required Parse parse,
  @required Uri authorizationEndpoint,
  @required Uri tokenEndpoint,
  @required String clientID,
  @required String redirectScheme,
  @required String redirectHost,
  @required String redirectPath,
}) {
  return IOParseOpenID.internal(
    parse: parse,
    authorizationEndpoint: authorizationEndpoint,
    tokenEndpoint: tokenEndpoint,
    clientID: clientID,
    redirectScheme: redirectScheme,
    redirectHost: redirectHost,
    redirectPath: redirectPath,
  );
}

class IOParseOpenID extends ParseOpenID {
  IOParseOpenID.internal({
    @required Parse parse,
    @required Uri authorizationEndpoint,
    @required Uri tokenEndpoint,
    @required String clientID,
    @required String redirectScheme,
    @required String redirectHost,
    @required String redirectPath,
  }) : super.internal(
          parse: parse,
          authorizationEndpoint: authorizationEndpoint,
          tokenEndpoint: tokenEndpoint,
          clientID: clientID,
          redirectScheme: redirectScheme,
          redirectHost: redirectHost,
          redirectPath: redirectPath,
        );

  @override
  Future<Uri> authorize(
    Uri authorizationUrl,
    AuthorizationCodeGrant grant,
    StateSetter stateSetter,
  ) async {
    if (await canLaunch(authorizationUrl.toString())) {
      launch(authorizationUrl.toString(), forceWebView: true)
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
