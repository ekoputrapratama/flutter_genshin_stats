<!--
This README describes the package. If you publish this package to pub.dev,
this README's contents appear on the landing page for your package.

For information about how to write a good package README, see the guide for
[writing package pages](https://dart.dev/guides/libraries/writing-package-pages).

For general information about developing packages, see the Dart guide for
[creating packages](https://dart.dev/guides/libraries/create-library-packages)
and the Flutter guide for
[developing packages and plugins](https://flutter.dev/developing-packages).
-->
# flutter_genshin_stats
a port of genshinstats for Python with some bug fixes

## How to install

```bash
flutter pub add flutter_genshin_stats
```

## Usage

```dart
import 'package:flutter_genshin_stats/genshin_stats.dart';

setCookie('ltoken', 'vSONEGVlkalkkalk');
setCookie('ltuid', '1843055509');
const uid = 843904344;

var response = await getUserStats(uid)
```

