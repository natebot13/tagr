part of 'plugin_cubit.dart';

@immutable
sealed class PluginState {}

final class PluginInitial extends PluginState {}

final class PluginsLoaded extends PluginState {
  final Map<String, Plugin> plugins;
  PluginsLoaded(this.plugins);
}
