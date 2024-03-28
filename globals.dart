import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:path_provider/path_provider.dart';

class Globals {
  Globals._();

  static init() async {
    if(Platform.isAndroid){
      documentPath = '/storage/emulated/0/Download/';
    }
    else{
      documentPath = (await getApplicationDocumentsDirectory()).path + "/";
    }

  }

  static const double borderRadius = 27;
  static String globalPath = "";
  static const double defaultPadding = 8;
  static String documentPath = '';
  static GlobalKey<AnimatedListState> audioListKey =
      GlobalKey<AnimatedListState>();
}
