part of parseserver_openid_flutter;

typedef StateSetter(AuthenticationState newState);

/// A class for authenticating against a parse server using openid.
abstract class ParseOpenID {
  /// The instance of the [ParseOpenID]
  static ParseOpenID _instance;

  /// The current [AuthenticationState] of the client.
  AuthenticationState __state;

  /// A stream of [AuthenticationState]s.
  final BehaviorSubject<AuthenticationState> _stateStream;

  /// The [Parse] instance.
  Parse _parse;

  /// The authorization endpoint
  String _authorizationEndpoint;

  /// The token endpoint
  String _tokenEndpoint;

  /// The scheme used for the redirect url. (Only used on native)
  String _redirectScheme;

  /// The host used for the redirect url. (Only used on native)
  String _redirectHost;

  /// The path used for the redirect url.
  /// On web, this should be the location of the openidredirect.html file.
  String _redirectPath;

  /// The client ID.
  String _clientID;

  /// The logout endpoint
  String _logoutEndpoint;

  /// Whether the [ParseOpenID] has been initialized.
  bool _initialized;

  /// The current [oauth2.Credentials]
  oauth2.Credentials _credentials;

  /// The scopes requested.
  static const List<String> scopes = ['openid', 'profile'];

  factory ParseOpenID() {
    if (_instance == null) {
      _instance = createOpenID();
    }

    return _instance;
  }

  /// Init the [ParseOpenID]. [Parse] must be initialized first.
  Future<void> init({
    Parse parse,
    @required String authorizationEndpoint,
    @required String tokenEndpoint,
    @required String clientID,
    String redirectScheme = "com.example.parseopenid",
    String redirectHost = "parseopenid.example.com",
    String redirectPath = "openidredirect.html",
    String logoutEndpoint,
  }) async {
    if (!(parse ?? Parse()).hasParseBeenInitialized()) {
      throw ParseOpenIDException(
        errorCode: ParseOpenIDException.ErrorParseNotInitialized,
        message: "Parse has not been initialized, yet.",
      );
    }

    if (!_initialized) {
      _authorizationEndpoint = authorizationEndpoint;
      _tokenEndpoint = tokenEndpoint;
      _redirectScheme = redirectScheme;
      _redirectHost = redirectHost;
      _redirectPath = redirectPath;
      _logoutEndpoint = logoutEndpoint;
      _parse = parse ?? Parse();
      _clientID = clientID;

      SharedPreferences sharedPreferences =
          await SharedPreferences.getInstance();

      // If the OAuth2 credentials have already been saved from a previous run, we just want to reload them.
      if (sharedPreferences.containsKey("oauthCredentials")) {
        oauth2.Credentials credentials = oauth2.Credentials.fromJson(
            sharedPreferences.getString("oauthCredentials"));

        try {
          if (_shouldRefresh(credentials)) {
            credentials = await credentials.refresh();
          }

          _authenticateParse(credentials);
        } on oauth2.AuthorizationException {
          await sharedPreferences.remove("oauthCredentials");
        }
      }

      _initialized = true;
      if (state == AuthenticationState.Uninitialized) {
        _state = AuthenticationState.Unauthenticated;
      }
    }
  }

  /// Login at the parse server.
  /// If the client is already considered to be authenticated or an authentication is in progress,
  /// nothing will happen, unless [force] is set to `true`.
  Future<void> login({bool force = false}) async {
    if (!_initialized) {
      throw ParseOpenIDException(
        errorCode: ParseOpenIDException.ErrorParseOpenIDNotInitialized,
        message: "ParseOpenID has not been initialized, yet.",
      );
    }

    if ((state != AuthenticationState.Authenticated &&
            state != AuthenticationState.Authenticating &&
            state != AuthenticationState.LogInOpen) ||
        force) {
      oauth2.AuthorizationCodeGrant grant = oauth2.AuthorizationCodeGrant(
          _clientID,
          Uri.parse(_authorizationEndpoint),
          Uri.parse(_tokenEndpoint));

      Uri authorizationUrl =
          grant.getAuthorizationUrl(createRedirectUrl(), scopes: scopes);

      Uri responseUrl = await authorize(authorizationUrl, _setState);

      oauth2.Client client =
          await grant.handleAuthorizationResponse(responseUrl.queryParameters);

      _authenticateParse(client.credentials);

      SharedPreferences sharedPreferences =
          await SharedPreferences.getInstance();

      await sharedPreferences.setString(
          "oauthCredentials", client.credentials.toJson());
    }
  }

  /// Logout at the parse server.
  Future<void> logout() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    await sharedPreferences.remove("oauthCredentials");

    await (await ParseUser.currentUser() as ParseUser)?.logout();

    if (_logoutEndpoint != null && _credentials != null) {
      await http.post(_logoutEndpoint, body: {
        "client_id": _clientID,
        "refresh_token": _credentials.refreshToken,
      });
    }
    _credentials = null;

    _state = AuthenticationState.Unauthenticated;
  }

  /// Create a new [ParseOpenID] in order to login [_parse] using an openid provider.
  ParseOpenID.internal()
      : _stateStream =
            BehaviorSubject.seeded(AuthenticationState.Uninitialized),
        __state = AuthenticationState.Uninitialized,
        _initialized = false;

  /// Update the current [AuthenticationState].
  set _state(AuthenticationState state) {
    __state = state;
    _stateStream.sink.add(state);
  }

  /// Get the current [AuthenticationState].
  AuthenticationState get state => __state;

  /// Get the [Stream] of [AuthenticationState]s.
  Stream<AuthenticationState> get stateStream => _stateStream.stream;

  /// Authorize the [grant], using the [authorizationUrl].
  /// The [stateSetter] is used to update the [AuthenticationState].
  Future<Uri> authorize(
    Uri authorizationUrl,
    StateSetter stateSetter,
  );

  /// Create the redirect url.
  Uri createRedirectUrl();

  /// Authenticate parse by using the provided
  void _authenticateParse(oauth2.Credentials credentials) async {
    _state = AuthenticationState.Authenticating;
    _credentials = credentials;

    ParseCloudFunction loginFunction = new ParseCloudFunction("openIDLogin");
    ParseResponse response = await loginFunction.execute(parameters: {
      "access_token": credentials.accessToken,
      "installation_id":
          (await ParseInstallation.currentInstallation()).installationId,
    });

    if (!response.success) {
      await logout();
      print(response.error);
      _state = AuthenticationState.Unauthenticated;
    } else {
      ParseUser user = ParseUser.clone(response.result["user"])
        ..fromJson(response.result["user"]);
      ParseCoreData().setSessionId(response.result["sessionToken"]);
      user.sessionToken = response.result["sessionToken"];
      user.saveInStorage(keyParseStoreUser);

      _state = AuthenticationState.Authenticated;
    }
  }

  /// Determine if the provided [oauth2.Credentials] should be refreshed.
  /// This will return true five seconds befor the credentials actually expire.
  static bool _shouldRefresh(oauth2.Credentials credentials) {
    return credentials.expiration != null &&
        DateTime.now()
            .isAfter(credentials.expiration.subtract(Duration(seconds: 5)));
  }

  /// Update the [AuthenticationState]. Same as [_state].
  _setState(AuthenticationState newState) {
    _state = newState;
  }

  /// The scheme used for the redirect url.
  String get redirectScheme => _redirectScheme;

  /// The host used for the redirect url.
  String get redirectHost => _redirectHost;

  /// The path used for the redirect url.
  String get redirectPath => _redirectPath;
}
