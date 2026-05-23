import 'package:flutter/material.dart';

extension RouteArgs on RouteSettings {
  T? as<T>() {
    if (arguments is T) return arguments as T;
    return null;
  }
}
