import 'package:flutter/material.dart';

class BaseProvider extends ChangeNotifier {
  String appState = "Ideal";


  BaseProvider(this.appState);

}
