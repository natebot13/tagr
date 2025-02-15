import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as path;
import 'package:tagr/src/constants.dart';
import 'package:tagr/src/plugin.dart';

part 'plugin_state.dart';

class PluginCubit extends Cubit<PluginState> {
  final Directory root;

  Directory get pluginsDirectory =>
      Directory(path.join(root.path, vaultFoldername, pluginsFoldername));

  PluginCubit(this.root) : super(PluginInitial()) {
    load();
  }

  void load() async {
    final plugins = <String, Plugin>{};
    await for (final pluginDir in pluginsDirectory.list()) {
      if (pluginDir is! Directory) continue;
      final plugin = await JavascriptPlugin.fromDirectory(pluginDir);
      if (plugin == null) continue;
      plugins[plugin.name] = plugin;
    }
    emit(PluginsLoaded(plugins));
  }
}
