import 'package:analyzer/dart/element/type.dart';
import 'package:source_gen/source_gen.dart';
import 'package:build/build.dart';
import 'package:mustache_template/mustache_template.dart' as mustache;
import 'package:analyzer/dart/element/element.dart';
import 'package:tagr/plugin_interface.dart';

class PluginGenerator extends GeneratorForAnnotation<PluginInterface> {
  @override
  Future<String> generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) async {
    if (element is! ClassElement) {
      throw InvalidGenerationSourceError(
        '@PluginInterface can only be used on classes.',
        element: element,
      );
    }

    final templateId = AssetId(
      buildStep.inputId.package,
      'lib/plugin_template.mustache',
    );
    final templateContent = await buildStep.readAsString(templateId);

    final methods = element.methods.where((m) => m.isAbstract).map((m) {
      return {
        'name': m.name,
        'capName': _capitalize(m.name),
        'returnType': m.returnType.getDisplayString(),
        'castResult': castResult(m.returnType),
        'isFuture': m.returnType.isDartAsyncFuture,
        'paramList': m.parameters.map((p) => '${p.type} ${p.name}').join(', '),
        'argList': m.parameters.map((p) => p.name).join(', '),
      };
    }).toList();

    final compiled =
        mustache.Template(templateContent, htmlEscapeValues: false);
    return compiled.renderString({
      'plugin_import': buildStep.inputId.uri.toString(),
      'plugin_class': element.name,
      'methods': methods,
    });
  }

  String _capitalize(String s) => s[0].toUpperCase() + s.substring(1);

  String castResult(DartType returnType) {
    if (returnType.isDartAsyncFuture) {
      return castResult((returnType as InterfaceType).typeArguments.first);
    } else {
      if (returnType.isDartCoreInt) {
        return 'result as int';
      } else if (returnType.isDartCoreDouble) {
        return 'result as double';
      } else if (returnType.isDartCoreString) {
        return 'result as String';
      } else if (returnType.isDartCoreBool) {
        return 'result as bool';
      } else if (returnType.isDartCoreList) {
        return 'List.from(result)';
      } else if (returnType.isDartCoreSet) {
        return 'Set.from(result)';
      } else if (returnType.isDartCoreMap) {
        return 'Map.from(result)';
      } else {
        return 'result';
      }
    }
  }
}

Builder getBuilder(BuilderOptions options) => LibraryBuilder(PluginGenerator());
