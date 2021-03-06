part of parseserver_openid_flutter;

/// An enum for specifying the state of the connection to the parse server (from an authentication view).
enum AuthenticationState {
  /// The package is uninitialized. A state has not yet been determined.
  Uninitialized,

  /// The user is authenticated and [Parse] is ready to use.
  Authenticated,

  /// The user is not authenticated, a log in option should be shown.
  Unauthenticated,

  /// Information where received, the package is authenticating [Parse]
  Authenticating,

  /// WEB ONLY!
  /// The browser window for logging in is open.
  /// You might want to show the user some kind of loading indication.
  /// If not, use this state like [AuthenticationState.Unauthenticated].
  LogInOpen,
}
