import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:ott/app/core/constant/api_constant.dart';
import 'package:ott/data/models/response/series_details.dart';

class SeriesProvider extends ChangeNotifier {
  SeriesDetailsResponse? _data;
  bool _loading = false;
  String? _error;

  SeriesDetailsResponse? get data => _data;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> loadSeries(int seriesId) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final url = Uri.parse(ApiConstant.seriesDetails(seriesId));
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonMap =
            jsonDecode(utf8.decode(response.bodyBytes));

        _data = SeriesDetailsResponse.fromJson(jsonMap);
      } else {
        _error = "Failed to load series (${response.statusCode})";
      }
    } catch (e) {
      _error = "Something went wrong while loading series";
      debugPrint("SeriesProvider error: $e");
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void clear() {
    _data = null;
    _error = null;
    _loading = false;
    notifyListeners();
  }
}
