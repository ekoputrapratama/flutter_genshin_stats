// ignore_for_file: avoid_print

import 'package:crypto/crypto.dart';

const Map<dynamic, String> artifactType = {
  '1': 'flower',
  '2': 'feather',
  '3': 'hourglass',
  '4': 'goblet',
  '5': 'crown',
};

const Map<String, String> characterIcons = {
  'PlayerGirl': 'Traveler',
  'PlayerBoy': 'Traveler',
  'Ambor': 'Amber',
  'Qin': 'Jean',
  'Hutao': 'Hu Tao',
  'Feiyan': 'Yanfei',
  'Kazuha': 'Kadehara Kazuha',
  'Sara': 'Kujou Sara',
  'Shougun': 'Raiden Shogun',
  'Tohma': 'Thoma',
};

abstract class AccountStats {
  List<dynamic>? characters;
  Map<String, dynamic>? stats;
  Map<String, dynamic>? teapot;
  List<dynamic>? explorations;
  dynamic spiralAbyss;
}

String recognizeCharacterIcon(String url) {
  // Recognizes a character's icon url and returns its name.
  var exp = RegExp('game_record/genshin/character_.*_(\\w+)(?:@\\dx)?.png',
      caseSensitive: false, multiLine: true);
  var match = exp.allMatches(url);
  print("allmatches ${match.toList()}");
  if (match.isEmpty) {
    print("$url is not a character icon or image url");
    throw Error();
  }
  var character = match.first.group(1)!;
  print("character name $character");
  return characterIcons[character] ?? character;
}

Map<String, dynamic> prettifyStats(dynamic data) {
  var s = data['stats'];
  var h = data['homes'];
  var characters = data['avatars'] ?? [];
  Map<String, dynamic> results = {
    'stats': {
      'achievements': s['achievement_number'],
      'active_days': s['active_day_number'],
      'characters': s['avatar_number'],
      'spiral_abyss': s['spiral_abyss'],
      'anemoculi': s['anemoculus_number'],
      'geoculi': s['geoculus_number'],
      'electroculi': s['electroculus_number'],
      'common_chests': s['common_chest_number'],
      'exquisite_chests': s['exquisite_chest_number'],
      'precious_chests': s['precious_chest_number'],
      'luxurious_chests': s['luxurious_chest_number'],
      'unlocked_waypoints': s['way_point_number'],
      'unlocked_domains': s['domain_number'],
    },
    'teapot': null,
    'characters': [],
    'explorations': [],
  };

  for (var i = 0; i < characters.length; i++) {
    var character = characters[i];
    if (character['rarity'] > 100) {
      character.rarity = character.rarity - 100;
    }
    results['characters'].add(character);
  }
  // print("homes $h");
  if (h != null) {
    for (var i = 0; i < h.length; i++) {}
    results['teapot'] = {
      'realms': [],
      'level': h[0]['level'],
      'comfort': h[0]['comfort_num'],
      'comfort_name': h[0]['comfort_level_name'],
      'comfort_icon': h[0]['comfort_level_icon'],
      'items': h[0]['item_num'],
      'visitors': h[0]['visit_num'],
    };

    for (var i = 0; i < h.length; i++) {
      var realm = h[i];

      results['teapot']['realms'].add(realm);
    }
  }
  var explorations = data['world_explorations'] ?? [];
  for (var i = 0; i < explorations.length; i++) {
    var exploration = explorations[i];
    results['explorations'].add({
      'name': exploration['name'],
      'explored': exploration['exploration_percentage'].round(),
      'type': exploration['type'],
      'icon': exploration['icon'],
      'level': exploration['level'],
      'offerings': exploration['offerings']
    });
  }

  return results;
}

List<Map<String, dynamic>> prettifyCharacters(dynamic data) {
  List<Map<String, dynamic>> results = [];

  for (var i = 0; i < data.length; i++) {
    var d = data[i];
    Map<String, dynamic> player = data['icon'].includes('Player')
        ? {
            'traveler_name': data['icon'].includes('Boy') ? 'Aether' : 'Lumin',
          }
        : {};
    var character = {
      'name': d['name'],
      'rarity': d['rarity'] < 100
          ? d['rarity']
          : d['rarity'] - 100, // aloy has 105 stars
      'element': d['element'],
      'level': d['level'],
      'friendship': d['fetter'],
      'constellation': d['constellations']
          .where((value) => value['is_actived'] == true)
          .toList()
          .length,
      'icon': d['icon'],
      'image': d['image'],
      'id': d['id'],
      'collab': d['rarity'] >= 100,
      'traveler_name': data['icon'].includes('Boy') ? 'Aether' : 'Lumin',
      'weapon': {
        'name': d['weapon']['name'],
        'rarity': d['weapon']['rarity'],
        'type': d['weapon']['type_name'],
        'level': d['weapon']['level'],
        'ascension': d['weapon']['promote_level'],
        'refinement': d['weapon']['affix_level'],
        'description': d['weapon']['desc'],
        'icon': d['weapon']['icon'],
        'id': d['weapon']['id'],
      },
      'artifacts': [],
      'constellations': [],
      'outfits': [],
    };

    var artifacts = d['reliquaries'];
    for (var j = 0; j < artifacts.length; j++) {
      var a = artifacts[j];
      var regex = RegExp("UI_RelicIcon_(\\d+)_\\d+",
          caseSensitive: false, multiLine: true);
      var matches = regex.allMatches(a['icon']);
      var setId = int.parse(matches.first.toString());
      var artifact = {
        'name': a['name'],
        'pos_name': artifactType[a['pos'].toString()],
        'full_pos_name': a['pos_name'],
        'pos': a['pos'],
        'rarity': a['rarity'],
        'level': a['level'],
        'set': {
          'name': a['set']['name'],
          'effect_type': [
            'none',
            'single',
            'classic'
          ][a['set']['affixes'].length],
          'effects': [],
          'set_id': setId, // type: ignore
          'id': a['set']['id'],
        },
        'icon': a['icon'],
        'id': a['id'],
      };
      var affixes = a['set']['affixes'] ?? [];
      for (var j = 0; j < affixes.length; j++) {
        var e = a['set']['affixes'][j];
        artifact['set']['effects'].add({
          'pieces': e['activation_number'],
          'effect': e['effect'],
        });
      }
    }

    var constellations = d['constellations'] ?? [];
    for (var i = 0; i < constellations.length; i++) {
      var c = constellations[i];
      character['constellations'].add({
        'name': c['name'],
        'effect': c['effect'],
        'is_activated': c['is_actived'],
        'index': c['pos'],
        'icon': c['icon'],
        'id': c['id'],
      });
    }
    var costumes = d['costumes'] ?? [];
    for (var i = 0; i < costumes.length; i++) {
      var c = costumes[i];
      character['outfits'].add({
        'name': c['name'],
        'icon': c['icon'],
        'id': c['id'],
      });
    }
    results.add(character);
  }

  return results;
}

List _fchars(dynamic d) {
  var results = [];
  for (int i = 0; i < d.length; i++) {
    var a = d[i];
    results.add({
      'value': a['value'],
      'name': recognizeCharacterIcon(a['avatar_icon']),
      'rarity': a['rarity'] < 100
          ? a['rarity']
          : a['rarity'] - 100, //aloy has 105 stars
      'icon': a['avatar_icon'],
      'id': a['avatar_id'],
    });
  }
  return results;
}

DateTime _toDate(x) {
  return DateTime.fromMillisecondsSinceEpoch(int.parse(x) * 1000);
}

String _toTime(x) {
  return DateTime.fromMillisecondsSinceEpoch(int.parse(x) * 1000)
      .toIso8601String();
}

Map prettifyAbyss(dynamic data) {
  var results = {
    'season': data['schedule_id'],
    'season_start_time': _toDate(data['start_time']),
    'season_end_time': _toDate(data['end_time']),
    'stats': {
      'total_battles': data['total_battle_times'],
      'total_wins': data['total_win_times'],
      'max_floor': data['max_floor'],
      'total_stars': data['total_star'],
    },
    'character_ranks': {
      'most_played': _fchars(data['reveal_rank']),
      'most_kills': _fchars(data['defeat_rank']),
      'strongest_strike': _fchars(data['damage_rank']),
      'most_damage_taken': _fchars(data['take_damage_rank']),
      'most_bursts_used': _fchars(data['normal_skill_rank']),
      'most_skills_used': _fchars(data['energy_skill_rank']),
    },
    'floors': [],
  };

  var floors = data['floors'] ?? [];
  for (var i = 0; i < floors.length; i++) {
    var f = floors[i];
    var floor = {
      'floor': f['index'],
      'stars': f['star'],
      'max_stars': f['max_star'],
      'icon': f['icon'],
      'chambers': [],
    };
    var levels = f['levels'] ?? [];
    for (var j = 0; j < levels.length; j++) {
      var l = levels[j];
      var chamber = {
        'chamber': l['index'],
        'stars': l['star'],
        'max_stars': l['max_star'],
        'has_halves': l['battles'].length == 2,
        'battles': [],
      };
      var battles = l['battles'];
      for (var k = 0; k < battles.length; k++) {
        var b = battles[k];
        var battle = {
          'half': b['index'],
          'timestamp': _toTime(b['timestamp']),
          'characters': [],
        };

        var avatars = b['avatars'];
        for (var z = 0; z < avatars.length; z++) {
          var c = avatars[z];
          battle['characters'].add({
            'name': recognizeCharacterIcon(c['icon']),
            'rarity': c['rarity'] < 100
                ? c['rarity']
                : c['rarity'] - 100, // aloy has 105 stars
            'level': c['level'],
            'icon': c['icon'],
            'id': c['id'],
          });
        }
        chamber['battles'].add(battle);
      }
      floor['chambers'].add(chamber);
    }
  }

  return results;
}

Map prettifyActivities(dynamic data) {
  var results = {};
  var activities = data['activities'];
  for (var i = 0; i < activities.length; i++) {
    Map activity = activities[i];
    activity.forEach((key, value) {
      if (activity[key]['exists_data']) {
        results[key] = activity[key];
      }
    });
  }

  return results;
}

Map prettifyNotes(dynamic data) {
  Map notes = {
    'resin': data['current_resin'],
    'until_resin_limit': data['resin_recovery_time'],
    'max_resin': data['max_resin'],
    'total_commissions': data['total_task_num'],
    'completed_commissions': data['finished_task_num'],
    'claimed_commission_reward': data['is_extra_task_reward_received'],
    'max_boss_discounts': data['resin_discount_num_limit'],
    'remaining_boss_discounts': data['remain_resin_discount_num'],
    'max_expeditions': data['max_expedition_num'],
    'realm_currency': data['current_home_coin'],
    'max_realm_currency': data['max_home_coin'],
    'until_realm_currency_limit': data['home_coin_recovery_time'],
    'expeditions': [],
  };
  var expeditions = data['expeditions'];
  for (var i = 0; i < expeditions.length; i++) {
    var exp = expeditions[i];
    notes['expeditions'].add({
      'icon': exp['avatar_side_icon'],
      'remaining_time': exp['remained_time'],
      'status': exp['status'],
    });
  }
  return notes;
}

List prettifyGameAccounts(dynamic data) {
  var results = [];

  for (var i = 0; i < data.length; i++) {
    var a = data[i];
    results.add({
      'uid': int.parse(a['game_uid']),
      'server': a['region_name'],
      'level': a['level'],
      'nickname': a['nickname'],
      // idk what these are for:
      'biz': a['game_biz'],
      'is_chosen': a['is_chosen'],
      'is_official': a['is_official'],
    });
  }
  return results;
}
