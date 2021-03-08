<p align="center">
    <img alt="Parse Logo" src="https://parseplatform.org/img/logo.svg" width="200">
  </a>
</p>

---

This package adds OpenID authentication to the [parse_server_sdk_flutter](https://pub.dev/packages/parse_server_sdk_flutter) package.

By authenticating against an access server and sending the access token to the parse server,
the client receives an sessionToken.  
Afterwards, this sessionToken is used to authenticate requests against the parse server.

There are multiple scenarios where parse needs to be authenticated against an central OpenID server.
1. You already have a network of applications with an central authentication server (eg. [KeyCloak](https://www.keycloak.org/)).
2. You want to provide SSO (single sign on) between different (web)-applications.
3. You want to have a flexible user database for easy expansion in the future.

## Getting Started

##### Add package
You have to add this package to your projects `pubspec.yaml`.

```yaml
dependencies:
  parseserver_openid_flutter: ">=0.0.1 <0.1.0"
```

##### Platform specific setup.
In order to receive the redirect link on native apps, you have to setup [uni_links](https://pub.dev/packages/uni_links).

###### Android
Add a new intent-filter in `android/app/src/main/AndroidManifest.xml`;

```xml
<manifest ...>
  <!-- ... other tags -->
  <application ...>
    <activity ...>
      <!-- ... other tags -->

      <intent-filter android:autoVerify="true">
        <action android:name="android.intent.action.VIEW" />
        <category android:name="android.intent.category.DEFAULT" />
        <category android:name="android.intent.category.BROWSABLE" />
        <data
            android:scheme="com.example.parseopenid"
            android:host="parseopenid.example.com"/>
      </intent-filter>
    </activity>
  </application>
</manifest>
```
###### IOS
Add the `CFBundleURLTypes` key to your `ios/Runner/Info.plist`.
```xml
<?xml ...>
<!-- ... other tags -->
<plist>
<dict>
  <!-- ... other tags -->
  <key>CFBundleURLTypes</key>
  <array>
    <dict>
      <key>CFBundleTypeRole</key>
      <string>Editor</string>
      <key>CFBundleURLName</key>
      <string>parseopenid.example.com</string>
      <key>CFBundleURLSchemes</key>
      <array>
        <string>com.example.parseopenid</string>
      </array>
    </dict>
  </array>
  <!-- ... other tags -->
</dict>
</plist>
```

##### Static web page.
In order to receive the authorization response on web,
you have to add the [`openidredirect.html`](https://raw.githubusercontent.com/fischerscode/ParseServer-OpenID-Flutter/master/auth-redirect/openidredirect.html) file to your `web/` folder.
Obviously you can also adjust this file. Just make sure you keep the `window.opener.postMessage(window.location.href, '*');` in.

##### Add the cloud function
As this package does not use the parse server 3th Party authorization, you have to add [this](https://raw.githubusercontent.com/fischerscode/ParseServer-OpenID-Flutter/master/cloudcode/main.js) cloud function to your cloud code.

**Make sure to check this part for updates, as you change the version of this package.**

##### Initialize ParseOpenID
Where ever you initialize `Parse()`, you now also want to initialize `ParseOpenID()`.

```dart
// These are the values of a local keycloak installation
initParse() {
  Parse parse = Parse();
  parseOpenID = ParseOpenID(
    authorizationEndpoint: Uri.parse(
        "https://192.168.178.65:8443/auth/realms/master/protocol/openid-connect/auth"),
    tokenEndpoint: Uri.parse(
        "https://192.168.178.65:8443/auth/realms/master/protocol/openid-connect/token"),
    redirectPath: "openidredirect.html",
    redirectHost: "parseopenid.example.com",
    redirectScheme: "com.example.parseopenid",
    clientID: "flutter",
    parse: parse,
    logoutEndpoint:
        "https://192.168.178.65:8443/auth/realms/master/protocol/openid-connect/logout",
  );
  parse
      .initialize(
        "myappID",
        "http://192.168.178.65:1337/parse",
      )
      .then((parse) => parseOpenID.init());
}
```

##### Use OpenID for authentication.

That's it!

You should now be able to log in and out.
```dart
/// Login to parse
Future<void> login() => ParseOpenID().login();

/// Log out of parse
Future<void> logout() => ParseOpenID().logout();
```