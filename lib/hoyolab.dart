import 'dart:math';

import 'prettify.dart';
import 'util.dart';
import 'genshin_stats.dart';

Future getLangs() async {
  var data =
      await fetchEndpoint('community/misc/wapi/langs', chinese: false, kwargs: {
    'params': {
      'gids': 2,
    },
  });
  var results = {};
  var langs = data['langs'] ?? [];
  for (var i = 0; i < langs.length; i++) {
    var lang = langs[i];
    results[lang['value']] = lang['name'];
  }

  return results;
}

Future hoyolabCheckIn({bool chinese = false}) {
  var url = 'https://sg-hk4e-api.hoyolab.com/event/sol/';
  var actId = 'e202102251931481';
  if (chinese) {
    url = 'https://api-takumi.mihoyo.com/event/bbs_sign_reward/';
    actId = 'e202009291139501';
  }

  return fetchEndpoint('${url}sign', chinese: chinese, kwargs: {
    'method': 'POST',
    'params': {'act_id': actId}
  });
}

Future getEntryPageList({chinese = false}) {
  const url =
      'https://sg-wiki-api.hoyolab.com/hoyowiki/wapi/get_entry_page_list';
  const kwargs = {
    'method': 'POST',
  };
  return fetchEndpoint(url, chinese: chinese, kwargs: kwargs);
}

Future getGameAccounts({bool chinese = false}) async {
  var url = 'https://api-os-takumi.hoyoverse.com/';
  if (chinese) {
    url = 'https://api-takumi.mihoyo.com/';
  }
  var data = await fetchEndpoint('${url}binding/api/getUserGameRolesByCookie');

  return prettifyGameAccounts(data['list']);
}

Future getRecordCard(int hoyolabUid, {bool chinese = false}) async {
  var cards = (await fetchGameRecordEndpoint('card/wapi/getGameRecordCard',
      chinese: chinese,
      kwargs: {
        'params': {
          'uid': hoyolabUid,
          'gids': 2,
        },
      }))['list'];

  return cards != null ? cards[0] : null;
}

Future getUidFromHoyolabUid(int hoyolabUid, {bool chinese = false}) async {
  var card = await getRecordCard(hoyolabUid, chinese: chinese);

  return card ? int.parse(card['game_role_id']) : null;
}

Future redeemCode(String code, {int uid = 0}) async {
  if (uid != 0) {
    return fetchEndpoint(
        'https://sg-hk4e-api.hoyoverse.com/common/apicdkey/api/webExchangeCdkey',
        chinese: false,
        kwargs: {
          'params': {
            'uid': uid,
            'region': recognizeServer(uid),
            'cdkey': code,
            'game_biz': 'hk4e_global',
            'lang': 'en',
          },
        });
  } else {
    var accounts = await getGameAccounts();
    var higherAccounts = accounts.where((acc) => acc['level'] >= 10);
    for (var i = 0; i < higherAccounts.length; i++) {
      var account = higherAccounts[i];
      await redeemCode(code, uid: account['uid']);
    }
  }
}

Future getRecommendedUsers({int pageSize = 0x10000}) async {
  return (await fetchEndpoint('community/user/wapi/recommendActive',
      chinese: false,
      kwargs: {
        'params': {
          'page_size': pageSize,
          'offset': 0,
          'gids': 2,
        },
      }))['list'];
}

Future getHotPosts(
    {int forumId = 1, int size = 100, String lang = 'en-us'}) async {
  return (await fetchEndpoint('community/post/api/forumHotPostFullList',
      chinese: false,
      kwargs: {
        'params': {
          'forum_id': forumId,
          'page_size': min(size, 0x4000),
          'lang': lang,
        },
      }))['posts'];
}
