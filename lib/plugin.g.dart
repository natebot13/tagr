// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// PluginGenerator
// **************************************************************************

import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:flutter_js/flutter_js.dart';
import 'package:tagr/plugin.dart';

class JavascriptPlugin extends Plugin {
  static const pluginSrc = 'main.js';

  final JavascriptRuntime jsRuntime;
  JavascriptPlugin._(super.name, this.jsRuntime);

  static Future<JavascriptPlugin?> fromDirectory(Directory pluginDir) async {
    final pluginName = path.basename(pluginDir.path);
    final pluginFile = File(path.join(pluginDir.path, pluginSrc));
    if (!await pluginFile.exists()) return null;
    final runtime = getJavascriptRuntime();
    runtime.evaluate(
      await pluginFile.readAsString(),
      sourceUrl: pluginFile.path,
    );
    return JavascriptPlugin._(pluginName, runtime);
  }

  @override
  Future<Set<String>> searchTags(String filepath) async {
    final args = json.encode([filepath]);
    final script = 'searchTags(...$args)';

    final evaluation = await jsRuntime.evaluateAsync(script);
    jsRuntime.executePendingJob();
    final promiseEvaluation = await jsRuntime.handlePromise(evaluation);
    final result = await promiseEvaluation.rawResult;

    return Set.from(result);
  }

  bool hasSearchTags() {
    final evaluation = jsRuntime.evaluate('typeof searchTags === "function"');
    return evaluation.rawResult;
  }
}
