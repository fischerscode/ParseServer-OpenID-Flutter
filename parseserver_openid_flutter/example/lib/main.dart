import 'dart:io';

import 'package:flutter/material.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk.dart';
import 'package:parseserver_openid_flutter/parseserver_openid_flutter.dart';

const HOST_IP = "192.168.178.65";

void main() {
  HttpOverrides.global = new MyHttpOverrides();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);
  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  ParseOpenID parseOpenID;

  _MyHomePageState() {
    Parse parse = Parse();
    parseOpenID = ParseOpenID();
    parse
        .initialize(
          "myappID",
          "http://$HOST_IP:1337/parse",
        )
        .then((parse) => parseOpenID.init(
              authorizationEndpoint:
                  "https://$HOST_IP:8443/auth/realms/master/protocol/openid-connect/auth",
              tokenEndpoint:
                  "https://$HOST_IP:8443/auth/realms/master/protocol/openid-connect/token",
              redirectPath: "openidredirect.html",
              redirectHost: "parseopenid.example.com",
              redirectScheme: "com.example.parseopenid",
              clientID: "flutter",
              parse: parse,
              logoutEndpoint:
                  "https://$HOST_IP:8443/auth/realms/master/protocol/openid-connect/logout",
            ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            StreamBuilder<AuthenticationState>(
              stream: parseOpenID.stateStream,
              builder: (context, snapshot) => Text(snapshot.data.toString()),
            ),
            OutlinedButton(
              onPressed: () async {
                authenticate();
              },
              child: Text("login"),
            ),
            OutlinedButton(
              onPressed: () async {
                parseOpenID.logout();
              },
              child: Text("logout"),
            )
          ],
        ),
      ),
    );
  }

  authenticate() async {
    parseOpenID.login();
  }
}

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}
