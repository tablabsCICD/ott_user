import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:ott/app/core/constant/api_constant.dart';
import 'package:ott/data/models/shorts.dart';

class ShortProvider extends ChangeNotifier {
  List<ShortModel> shorts = [];
  ShortDetailModel? shortDetail;
  bool isLoading = false;

  Future<void> fetchShorts() async {
    try {
      isLoading = true;
      notifyListeners();

      var url = Uri.parse(ApiConstant.shortsMaster);
      var response = await http.get(url);
      final data = jsonDecode(response.body);

      shorts =
          (data["data"] as List).map((e) => ShortModel.fromJson(e)).toList();
    } catch (e) {
      print("Shorts Fetch Error → $e");
    }

    isLoading = false;
    notifyListeners();
  }

  Future<void> fetchShortDetail(int id, int userId) async {
    try {
      isLoading = true;
      notifyListeners();

      var url = Uri.parse(ApiConstant.shortsDetails(id, userId));
      var response = await http.get(url);
      final data = jsonDecode(response.body);

      shortDetail = ShortDetailModel.fromJson(data["data"]);
    } catch (e) {
      print("Short Detail Error → $e");
    }

    isLoading = false;
    notifyListeners();
  }
}
