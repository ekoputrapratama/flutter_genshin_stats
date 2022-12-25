library flutter_genshin_stats;

// You have generated a new plugin project without specifying the `--platforms`
// flag. A plugin project with no platform support was generated. To add a
// platform, run `flutter create -t plugin --platforms <platforms> .` under the
// same directory. You can also find a detailed instruction on how to add
// platforms in the `pubspec.yaml` at
// https://flutter.dev/docs/development/packages-and-plugins/developing-packages#plugin-platforms.

// ignore_for_file: unnecessary_brace_in_string_interps, constant_identifier_names

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:crypto/crypto.dart';

import 'prettify.dart';
import 'util.dart';

const OS_DS_SALT = '6cqshh5dhw73bzxn20oexa9k516chk7s';
const CN_DS_SALT = 'xV8v4Qu54lUKrEYFZkJhB8cuOh9Asafs';
const OS_TAKUMI_URL = 'https://api-os-takumi.mihoyo.com/'; // overseas
const CN_TAKUMI_URL = 'https://api-takumi.mihoyo.com/'; // chinese
const OS_GAME_RECORD_URL = 'https://bbs-api-os.hoyoverse.com/game_record/';
const CN_GAME_RECORD_URL = 'https://api-takumi.mihoyo.com/game_record/app/';

final _random = Random();
var cookies = {};

void setCookie(String key, String value) {
  cookies[key] = value;
  // print("cookies $cookies");
}

String generateCnDs(String salt, dynamic body, List<String> query) {
  var t = DateTime.now().millisecondsSinceEpoch;
  var r = _random.nextInt((200000 - 100001 + 1)) + 100001;
  var b = body.toString();
  var q = query.join('&');
  var h = md5.convert(utf8.encode("salt=$salt&t=$t&r=$r&b=$b&q=$q")).toString();

  return "${t},${r},${h}";
}

String generateDs(String salt) {
  // const t = DateTime.now().millisecond / 1000;
  var t = (DateTime.now().millisecondsSinceEpoch / 1000).round();
  var r = randomChars(6);
  var h = md5.convert(utf8.encode("salt=${salt}&t=${t}&r=${r}")).toString();

  return "${t},${r},${h}";
}

var retryCount = 0;
Future _request(String method, String url,
    {Map<dynamic, dynamic> kwargs = const {}}) async {
  HttpClient client = HttpClient();
  HttpClientRequest clientRequest;
  String params = '';

  var paramsMap = kwargs['params'];
  if (paramsMap != null && paramsMap is Map) {
    params += '?';

    int index = 0;
    paramsMap.forEach((key, value) {
      if (index == 0) {
        params += "${key}=${value}";
      } else {
        params += "&${key}=${value}";
      }
      index++;
    });
    // print("parameters $params");
  }
  // ignore: prefer_typing_uninitialized_variables
  var body;
  if (kwargs['body'] != null) {
    body = kwargs['body'];
  }

  if (method.toLowerCase() == 'post') {
    clientRequest = await client.postUrl(Uri.parse(url + params));
  } else {
    clientRequest = await client.getUrl(Uri.parse(url + params));
  }

  var headers = kwargs['headers'];
  if (headers is Map) {
    headers.forEach((key, value) {
      clientRequest.headers.add(key, value);
    });
  }
  if (body != null) {
    clientRequest.add(utf8.encode(json.encode(body)));
  }

  cookies.forEach((key, value) {
    clientRequest.cookies.add(Cookie(key, value));
  });

  HttpClientResponse clientResponse = await clientRequest.close();
  var response = await clientResponse.transform(utf8.decoder).join();

  var data = json.decode(response);
  if (data != null) {
    var retcode = data['retcode'];
    return {
      'retcode': retcode,
      'message': data['message'],
      'data': data['data'],
    };
  }

  throw Error();
}

Future fetchEndpoint(String endpoint,
    {bool chinese = false, Map kwargs = const {}}) async {
  var headers = {};
  var method = kwargs['method'] ?? 'get';
  var url = endpoint;

  if (chinese) {
    var ds = generateCnDs(CN_DS_SALT, kwargs['body'], kwargs['params']);
    headers['ds'] = ds;
    headers['x-rpc-app_version'] = '2.11.1';
    headers['x-rpc-client_type'] = '5';
  } else {
    var ds = generateDs(OS_DS_SALT);
    headers['ds'] = ds;
    headers['x-rpc-app_version'] = '1.5.0';
    headers['x-rpc-client_type'] = '4';
  }

  var h = kwargs['headers'];
  if (h != null && h is Map) {
    h.forEach((key, value) {
      headers[key] = value;
    });
  }

  // cannot assign to a constant parameter
  // so just make a new mutable map based on kwargs
  // and assign the headers
  var options = Map.of(kwargs);
  options['headers'] = headers;

  return _request(method, url, kwargs: options);
}

Future fetchGameRecordEndpoint(String endpoint,
    {bool chinese = false, Map kwargs = const {}}) {
  var baseUrl = OS_GAME_RECORD_URL;
  if (chinese) {
    baseUrl = CN_GAME_RECORD_URL;
  }
  var url = [baseUrl, endpoint].join();
  return fetchEndpoint(url, chinese: chinese, kwargs: kwargs);
}

Future getUserStats(int uid,
    {bool equipment = false, String lang = 'en-us'}) async {
  var server = recognizeServer(uid);
  Map<dynamic, dynamic> kwargs = {
    'params': {
      'server': server,
      'role_id': uid,
    },
    'headers': {
      'x-rpc-language': lang,
    }
  };
  var data = await fetchGameRecordEndpoint('genshin/api/index',
      chinese: isChinese(uid), kwargs: kwargs);

  var stats = prettifyStats(data);

  if (equipment) {
    stats['characters'] =
        await getCharacters(uid, characterIds: data['characters'], lang: lang);
  }

  return stats;
}

Future getCharacters(int uid,
    {List<int>? characterIds = const [], lang = 'en-us'}) async {
  if (characterIds == null) {
    var characters = (await getUserStats(uid,
            equipment: false, lang: 'en-us'))['characters'] ??
        [];
    characterIds = [];
    characters.forEach((character) {
      characterIds!.add(character.id);
    });
  }

  var server = recognizeServer(uid);
  Map<String, dynamic> kwargs = {
    'method': 'POST',
    'body': {
      'character_ids': characterIds,
      'role_id': uid,
      'server': server,
    },
    'headers': {
      'x-rpc-language': lang,
    }
  };
  var data = await fetchGameRecordEndpoint('genshin/api/index',
      chinese: isChinese(uid), kwargs: kwargs);

  return prettifyCharacters(data['avatars']);
}

Future getSpiralAbyss(int uid, {bool previous = false}) async {
  var server = recognizeServer(uid);
  var scheduleType = previous ? 2 : 1;
  Map kwargs = {
    'params': {
      'server': server,
      'role_id': uid,
      'schedule_type': scheduleType,
    },
  };
  var data = await fetchGameRecordEndpoint('genshin/api/spiralAbyss',
      chinese: isChinese(uid), kwargs: kwargs);

  return prettifyAbyss(data);
}
