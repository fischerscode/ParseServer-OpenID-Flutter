import 'dart:html';

import 'package:parseserver_openid_flutter/parseserver_openid_flutter.dart';

ParseOpenID createOpenID() {
  return HttpParseOpenID.internal();
}

class HttpParseOpenID extends ParseOpenID {
  HttpParseOpenID.internal() : super.internal();

  @override
  Future<Uri> authorize(
    Uri authorizationUrl,
    StateSetter stateSetter,
  ) {
    stateSetter(AuthenticationState.LogInOpen);
    window.open(authorizationUrl.toString(), "Authentication",
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
