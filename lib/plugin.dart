import 'dart:async';
import 'plugin_interface.dart';

@PluginInterface()
abstract class Plugin {
  final String _name;
  String get name => _name;
  Plugin(this._name);
  Future<Set<String>> searchTags(String filepath);
}
