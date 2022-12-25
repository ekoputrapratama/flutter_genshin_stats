// ignore_for_file: constant_identifier_names

import 'genshin_stats.dart';
import 'util.dart';

const OS_URL = 'https://hk4e-api-os.hoyoverse.com/event/sol/'; // overseas
const OS_ACT_ID = 'e202102251931481';
const CN_URL =
    'https://api-takumi.mihoyo.com/event/bbs_sign_reward/'; // chinese
const CN_ACT_ID = 'e202009291139501';

class DailyRewardInfo {
  var signedIn = false;
  var claimedReward = 0;

  DailyRewardInfo(this.signedIn, this.claimedReward);
}

Future fetchDailyEndpoint(String endpoint,
    {bool chinese = false, Map kwargs = const {}}) {
  var daily = chinese ? [CN_URL, CN_ACT_ID] : [OS_URL, OS_ACT_ID];

  var options = Map.of(kwargs);
  var params = Map.of(kwargs['params']);
  params['act_id'] = daily[1];
  options['params'] = params;
  var url = [daily[0], endpoint].join();

  return fetchEndpoint(url, chinese: chinese, kwargs: options);
}

Future<DailyRewardInfo> getDailyRewardInfo({bool chinese = false}) async {
  var data = await fetchDailyEndpoint('info', chinese: chinese);

  return DailyRewardInfo(data['is_sign'], data['total_sign_day']);
}

Future getMonthlyReward({chinese = false, lang = 'en-us'}) async {
  return (await fetchDailyEndpoint('home', chinese: chinese, kwargs: {
    'params': {'lang': lang},
  }))['awards'];
}

Future claimDailyReward(int uid, {bool chinese = false, lang = 'en-us'}) async {
  var info = await getDailyRewardInfo(chinese: chinese);

  if (info.signedIn) return;

  const params = {};

  if (chinese) {
    params['game_uid'] = uid;
    params['region'] = recognizeServer(uid);
  }

  params['lang'] = lang;
  await fetchDailyEndpoint('sign',
      chinese: chinese, kwargs: {'method': 'POST', 'params': params});
  var rewards = await getMonthlyReward(chinese: chinese, lang: lang);

  return rewards[info.claimedReward];
}
