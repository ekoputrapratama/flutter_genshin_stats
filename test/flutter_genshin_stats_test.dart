import 'package:flutter_genshin_stats/genshin_stats.dart';
import 'package:flutter_test/flutter_test.dart';

const ltoken = '3RP65h09ZzqNb8KJYJupWIU6vpfeSxsLOh6Diu8V';
const ltuid = 189215131;
const cookieToken = '7TONU3H0rxuFQwNYo5lvblU13pkNODS7v9RIv6rX';

void main() {
  test('genshinstats : set cookies', () {
    setCookie('ltuid', "$ltuid");
    setCookie('ltoken', ltoken);
    setCookie('cookie_token', cookieToken);
    expect(cookies['ltoken'], equals(ltoken));
    expect(cookies['ltuid'], equals('$ltuid'));
    expect(cookies['cookie_token'], equals(cookieToken));
  });
  test('genshinstats : get characters', () async {
    setCookie('ltuid', "$ltuid");
    setCookie('ltoken', ltoken);
    setCookie('cookie_token', cookieToken);

    var stats = await getUserStats(849931282);
    expect(stats, isInstanceOf<Map>());
  });

  tearDownAll(() {
    cookies.clear();
  });
  // test('$MethodChannelFlutterGenshinstats is the default instance', () {
  //   expect(initialPlatform, isInstanceOf<MethodChannelFlutterGenshinstats>());
  // });
}
