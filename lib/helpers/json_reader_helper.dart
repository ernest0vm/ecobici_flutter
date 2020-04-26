import 'dart:convert';
import 'package:flutter/material.dart';

class JsonReaderHelper {

  Future<List> getInfoBikes(BuildContext context) async {
    String _path = 'assets/json/bikes.json';
    String source = await DefaultAssetBundle.of(context).loadString(_path);
    List stationList = await json.decode(source.toString());
    return stationList;
  }

}

final jsonReader = JsonReaderHelper();