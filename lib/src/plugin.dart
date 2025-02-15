import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;

import 'package:flutter_js/flutter_js.dart';

abstract class Plugin {
  String get name;
  Future<Set<String>> searchTags(String filepath);
}

// A wrapper around the runtime to call the right library function
class JavascriptPlugin implements Plugin {
  static const pluginSrc = 'main.js';

  @override
  final String name;
  final JavascriptRuntime runtime;
  final implementedFunctions = <String>{};

  void ensureImplemented(String name) {
    if (runtime.evaluate("typeof $name == 'function';").rawResult) return;
    throw UnimplementedError();
  }

  JavascriptPlugin._(this.name, this.runtime) {
    for (final name in runtime.localContext.keys) {
      implementedFunctions.add(name);
    }
  }

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
    ensureImplemented('searchTags');
    final script = 'searchTags(${json.encode(filepath)});';
    final result = await runtime.evaluateAsync(script);
    runtime.executePendingJob();
    final promiseResolved = await runtime.handlePromise(result);
    return Set.from(await promiseResolved.rawResult);
  }
}
