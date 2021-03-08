import 'package:flutter/foundation.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk.dart';
import 'package:parseserver_openid_flutter/parseserver_openid_flutter.dart';

ParseOpenID createOpenID({
  Parse parse,
  @required Uri authorizationEndpoint,
  @required Uri tokenEndpoint,
  @required String clientID,
  @required String redirectScheme,
  @required String redirectHost,
  @required String redirectPath,
  String logoutEndpoint,
}) {
  throw UnimplementedError("STUB!");
}
