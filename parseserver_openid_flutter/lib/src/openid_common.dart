import 'package:flutter/foundation.dart';
import 'package:openid_client/openid_client.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk.dart';

import 'openid_stub.dart'
    if (dart.library.io) 'openid_io.dart'
    if (dart.library.html) 'openid_html.dart';

abstract class ParseOpenID {
  static ParseOpenID _instance;

  final Parse _parse;
  final Uri _openidServer;
  final String _clientID;

  static final List<String> scopes = List<String>.of(['openid', 'profile']);

  factory ParseOpenID({
    Parse parse,
    @required Uri openidServer,
    @required String clientID,
  }) {
    if (_instance == null) {
      _instance = createOpenID(
        parse: parse,
        openidServer: openidServer,
        clientID: clientID,
      );
    }
    return _instance;
  }

  ParseOpenID.internal(
    this._parse,
    this._openidServer,
    this._clientID,
  );

  void authenticate() async {
    Issuer issuer = await Issuer.discover(_openidServer);

    Client client = new Client(issuer, _clientID);

    Credential credential =
        await authenticateInBrowser(issuer: issuer, client: client);

    authenticateWithCredentials(credential);
  }

  Future<Credential> authenticateInBrowser({
    @required Issuer issuer,
    @required Client client,
  });

  void authenticateWithCredentials(Credential credential) {
    print(credential != null ? credential.toJson() : "No credentials, yet.");

    return null;
  }
}
