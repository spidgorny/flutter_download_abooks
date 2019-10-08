import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get_ip/get_ip.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' show parse;
import 'package:http/http.dart' as http;
import 'package:share/receive_share_state.dart';
import 'package:share/share.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Download Audiobooks',
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

class ShareExample {
  String mimeType;
  String title;
  String text;
  String path;
  List<String> shares;

  ShareExample({this.mimeType, this.title, this.text, this.path, this.shares});
}

class _MyHomePageState extends ReceiveShareState<MyHomePage> {
  static ShareExample exampleShare = ShareExample(
      mimeType: "text/plain",
      title:
          "Что мой сын должен знать об устройстве этого мира (fb2) | Флибуста",
      text: "https://audioknigi.club/martin-dzhordzh-peschanye-koroli",
      path: null,
      shares: []);

  String ip;
  String url;
  String pictureURL;
  String title;
  String cookie;

  @override
  void initState() {
    super.initState();
    enableShareReceiving();
    this.asyncInitState();
  }

  void asyncInitState() async {
    var ip = await GetIp.ipAddress;
    setState(() {
      this.ip = ip;
    });
  }

  @override
  void receiveShare(Share share) async {
    setState(() {
      this.url = share.text;
    });
    print(share.text);
    var response = await http.get(url);
    print('Response status: ${response.statusCode}');
//    print('Response body: ${response.body}');
//    print(response.headers);
    this.cookie = response.headers['set-cookie'];

    dom.Document document = parse(response.body);
    var picture = document.querySelector('div.picture-side img');
    if (picture != null) {
      setState(() {
        this.pictureURL = picture.attributes['src'];
      });
    }

    var title = document.querySelector('head title');
    if (title != null) {
      setState(() {
        this.title = title.innerHtml;
      });
    }

    var player = document.querySelector('div.player-side');
//    print(player);
    if (player != null) {
      var dataGlobalID = player.attributes['data-global-id'];
//      print(dataGlobalID);

      var bidUri =
          Uri.parse('https://audioknigi.club/ajax/bid/' + dataGlobalID);
      var request = new http.Request('post', bidUri);
      request.headers.addAll({
        'content-type': 'application/x-www-form-urlencoded; charset=UTF-8',
        'cookie': this.cookie + '; a_ismobile=0',
        'user-agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/77.0.3865.90 Safari/537.36',
        'origin': 'https://audioknigi.club',
        'sec-fetch-mode': 'cors',
        'sec-fetch-site': 'same-origin',
        'x-requested-with': 'XMLHttpRequest',
      });
      var client = http.Client();
      var streamedResponse = await client.send(request);
      var response2 = await http.Response.fromStream(streamedResponse);
      if (response2.body.startsWith('{')) {
        var json = jsonDecode(response2.body);
        var aItems = jsonDecode(json.aItems);
        print(aItems);
      } else {
        print(response2.body);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(this.url ?? 'Download Audiobooks'),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          Text(
            'IP: ' + (this.ip ?? ''),
            textAlign: TextAlign.left,
          ),
          Text(
            'URL: ' + (this.url ?? ''),
            textAlign: TextAlign.left,
          ),
          Text(
            'Title: ' + (this.title ?? ''),
          ),
          this.pictureURL != null
              ? Image.network(this.pictureURL)
              : Container(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => {
          this.receiveShare(Share.plainText(
              title: exampleShare.title, text: exampleShare.text))
        },
        tooltip: 'Increment',
        child: Icon(Icons.add),
      ), //
    );
  }
}
