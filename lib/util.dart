import 'dart:math';

final _random = Random();
const servers = {
  '1': 'cn_gf01',
  '2': 'cn_gf01',
  '5': 'cn_qd01',
  '6': 'os_usa',
  '7': 'os_euro',
  '8': 'os_asia',
  '9': 'os_cht',
};
String recognizeServer(int uid) {
  var server = servers[uid.toString()[0]];

  if (server != null) {
    return server;
  } else {
    print("UID $uid isn't associated with any server");
    throw Error();
  }
}

String randomChars(int length) {
  var result = '';
  var characters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz';
  var charactersLength = characters.length;
  for (var i = 0; i < length; i++) {
    result += characters[0 + _random.nextInt(charactersLength - 0)];
  }
  return result;
}

bool isChinese(int uid) {
  return uid.toString().startsWith('ch') ||
      uid.toString().startsWith('1') ||
      uid.toString().startsWith('5');
}
