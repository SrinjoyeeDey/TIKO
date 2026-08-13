import 'package:flutter/material.dart';

import 'game_map_1913_platform_stub.dart'
    if (dart.library.html) 'game_map_1913_platform_web.dart'
    if (dart.library.io) 'game_map_1913_platform_io.dart';

Widget getGameMap1913View() => getPlatformGameMap1913View();
