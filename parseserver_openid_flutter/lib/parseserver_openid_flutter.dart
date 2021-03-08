library parseserver_openid_flutter;

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:oauth2/oauth2.dart' as oauth2;
import 'package:parse_server_sdk_flutter/parse_server_sdk.dart';
import 'package:rxdart/subjects.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'src/openid_stub.dart'
    if (dart.library.io) 'src/openid_io.dart'
    if (dart.library.html) 'src/openid_html.dart';

part 'src/authentication_state.dart';
part 'src/exceptions.dart';
part 'src/openid_common.dart';
