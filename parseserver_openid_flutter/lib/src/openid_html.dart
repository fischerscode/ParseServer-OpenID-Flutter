import 'dart:html';

import 'package:flutter/foundation.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk.dart';
import 'package:parseserver_openid_flutter/parseserver_openid_flutter.dart';

ParseOpenID createOpenID({
  @required Parse parse,
  @required Uri authorizationEndpoint,
  @required Uri tokenEndpoint,
  @required String clientID,
  @required String redirectScheme,
  @required String redirectHost,
  @required String redirectPath,
  String logoutEndpoint,
}) {
  return HttpParseOpenID.internal(
    parse: parse,
    authorizationEndpoint: authorizationEndpoint,
    tokenEndpoint: tokenEndpoint,
    clientID: clientID,
    redirectScheme: redirectScheme,
    redirectHost: redirectHost,
    redirectPath: redirectPath,
    logoutEndpoint: logoutEndpoint,
  );
}

class HttpParseOpenID extends ParseOpenID {
  WindowBase _popupWin;

  HttpParseOpenID.internal({
    @required Parse parse,
    @required Uri authorizationEndpoint,
    @required Uri tokenEndpoint,
    @required String clientID,
    @required String redirectScheme,
    @required String redirectHost,
    @required String redirectPath,
    String logoutEndpoint,
  }) : super.internal(
          parse: parse,
          authorizationEndpoint: authorizationEndpoint,
          tokenEndpoint: tokenEndpoint,
          clientID: clientID,
          redirectScheme: redirectScheme,
          redirectHost: redirectHost,
          redirectPath: redirectPath,
          logoutEndpoint: logoutEndpoint,
        );

  @override
  Future<Uri> authorize(
    Uri authorizationUrl,
    StateSetter stateSetter,
  ) {
    stateSetter(AuthenticationState.LogInOpen);
    _popupWin = window.open(authorizationUrl.toString(), "Authentication",
        "width=800, height=900, scrollbars=yes");
    // _popupWin.addEventListener("onunload",
    //     (event) => stateSetter(AuthenticationState.Unauthenticated));

    return window.onMessage
        .map((event) => event.data.toString())
        .firstWhere((e) => e.contains("session_state="))
        .then((value) => Uri.parse(value));
  }

  @override
  Uri createRedirectUrl() {
    return Uri(
      host: Uri.base.host,
      scheme: Uri.base.scheme,
      port: Uri.base.port,
      path: redirectPath,
    );
  }
}
