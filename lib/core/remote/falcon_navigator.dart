import 'package:flutter/material.dart';

abstract final class FalconNavigator {
  static final GlobalKey<NavigatorState> key = GlobalKey<NavigatorState>();

  static NavigatorState? get state => key.currentState;

  static void goHome() {
    state?.popUntil((Route<dynamic> route) => route.isFirst);
  }
}
