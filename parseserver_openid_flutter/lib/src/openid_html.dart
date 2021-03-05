import 'package:flutter/foundation.dart';
import 'package:openid_client/openid_client_browser.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk.dart';
import 'package:parseserver_openid_flutter/src/openid_common.dart';

ParseOpenID createOpenID({
  Parse parse,
  @required Uri openidServer,
  @required String clientID,
}) {
  return HttpParseOpenID.internal(
      openidServer: openidServer, clientID: clientID, parse: parse);
}

class HttpParseOpenID extends ParseOpenID {
  HttpParseOpenID.internal({
    Parse parse,
    @required Uri openidServer,
    @required String clientID,
  }) : super.internal(parse, openidServer, clientID);

  @override
  Future<Credential> authenticateInBrowser({
    Issuer issuer,
    Client client,
  }) async {
    var authenticator = new Authenticator(
      client,
      scopes: ParseOpenID.scopes,
    );

    Credential credential = await authenticator.credential;

    // print(credential.toJson());

    if (credential == null) {
      // authenticator.authorize();
      return null;
    } else {
      return credential;
    }
  }
}
