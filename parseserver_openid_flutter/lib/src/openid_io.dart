import 'package:flutter/foundation.dart';
import 'package:openid_client/openid_client_io.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk.dart';
import 'package:parseserver_openid_flutter/src/openid_common.dart';
import 'package:url_launcher/url_launcher.dart';

ParseOpenID createOpenID({
  Parse parse,
  @required Uri openidServer,
  @required String clientID,
}) {
  return IOParseOpenID.internal(
      openidServer: openidServer, clientID: clientID, parse: parse);
}

class IOParseOpenID extends ParseOpenID {
  IOParseOpenID.internal({
    Parse parse,
    @required Uri openidServer,
    @required String clientID,
  }) : super.internal(parse, openidServer, clientID);

  @override
  Future<Credential> authenticateInBrowser({
    Issuer issuer,
    Client client,
  }) async {
    urlLauncher(String url) async {
      if (await canLaunch(url)) {
        await launch(url, forceWebView: true);
      } else {
        throw 'Could not launch $url';
      }
    }

    var authenticator = new Authenticator(
      client,
      scopes: ParseOpenID.scopes,
      port: 4200,
      urlLancher: urlLauncher,
    );

    Credential c = await authenticator.authorize();
    closeWebView();

    return c;
  }
}
