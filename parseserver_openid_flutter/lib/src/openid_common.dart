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
  final Parse _parse;

  /// The authorization endpoint
  final Uri authorizationEndpoint;

  /// The token endpoint
  final Uri tokenEndpoint;

  /// The scheme used for the redirect url. (Only used on native)
  final String redirectScheme;

  /// The host used for the redirect url. (Only used on native)
  final String redirectHost;

  /// The path used for the redirect url.
  /// On web, this should be the location of the openidredirect.html file.
  final String redirectPath;

  /// The client ID.
  final String _clientID;

  /// Whether the [ParseOpenID] has been initialized.
  bool _initialized;

  /// The scopes requested.
  static const List<String> scopes = ['openid', 'profile'];

  factory ParseOpenID({
    Parse parse,
    @required Uri authorizationEndpoint,
    @required Uri tokenEndpoint,
    @required String clientID,
    String redirectScheme = "com.example.parseopenid",
    String redirectHost = "parseopenid.example.com",
    String redirectPath = "openidredirect.html",
  }) {
    if (_instance == null) {
      _instance = createOpenID(
        parse: parse ?? Parse(),
        clientID: clientID,
        tokenEndpoint: tokenEndpoint,
        authorizationEndpoint: authorizationEndpoint,
        redirectScheme: redirectScheme,
        redirectHost: redirectHost,
        redirectPath: redirectPath,
      );
    }

    return _instance;
  }

  /// Init the [ParseOpenID]. [Parse] must be initialized first.
  Future<void> init() async {
    if (!_parse.hasParseBeenInitialized()) {
      throw ParseOpenIDException(
        errorCode: ParseOpenIDException.ErrorParseNotInitialized,
        message: "Parse has not been initialized, yet.",
      );
    }

    if (!_initialized) {
      SharedPreferences sharedPreferences =
          await SharedPreferences.getInstance();

      // If the OAuth2 credentials have already been saved from a previous run, we just want to reload them.
      if (sharedPreferences.containsKey("oauthCredentials")) {
        oauth2.Credentials credentials = oauth2.Credentials.fromJson(
            sharedPreferences.getString("oauthCredentials"));

        if (_shouldRefresh(credentials)) {
          credentials = await credentials.refresh();
        }

        _authenticateParse(credentials);
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
  void login({bool force = false}) async {
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
      //TODO: logout and revoke tokens

      oauth2.AuthorizationCodeGrant grant = oauth2.AuthorizationCodeGrant(
          _clientID, authorizationEndpoint, tokenEndpoint);

      Uri authorizationUrl = grant.getAuthorizationUrl(createRedirectUrl());

      Uri responseUrl = await authorize(authorizationUrl, grant, _setState);

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
  /// If the client is not considered to be [AuthenticationState.Authenticated] nothing will happen.
  void logout() async {
    if (state == AuthenticationState.Authenticated) {
      SharedPreferences sharedPreferences =
          await SharedPreferences.getInstance();
      await sharedPreferences.remove("oauthCredentials");

      await (await ParseUser.currentUser() as ParseUser).logout();

      _state = AuthenticationState.Unauthenticated;

      //TODO: revoke tokens
    }
  }

  /// Create a new [ParseOpenID] in order to login [_parse] using an openid provider.
  ParseOpenID.internal({
    @required Parse parse,
    @required this.authorizationEndpoint,
    @required this.tokenEndpoint,
    @required String clientID,
    @required this.redirectScheme,
    @required this.redirectHost,
    @required this.redirectPath,
  })  : _parse = parse,
        _clientID = clientID,
        _stateStream =
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
    oauth2.AuthorizationCodeGrant grant,
    StateSetter stateSetter,
  );

  /// Create the redirect url.
  Uri createRedirectUrl();

  /// Authenticate parse by using the provided
  void _authenticateParse(oauth2.Credentials credentials) async {
    _state = AuthenticationState.Authenticating;
    print(credentials.accessToken);

    ParseCloudFunction loginFunction = new ParseCloudFunction("openIDLogin");
    ParseResponse response = await loginFunction.execute(parameters: {
      "access_token": credentials.accessToken,
      "installation_id":
          (await ParseInstallation.currentInstallation()).installationId,
    });

    if (!response.success) {
      print(response.error);
      _state = AuthenticationState.Unauthenticated;
    } else {
      ParseUser user = ParseUser.clone(response.result["user"]);
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
}
