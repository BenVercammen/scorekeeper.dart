
import 'dart:io';

import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
// ignore: import_of_legacy_library_into_null_safe
import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:scorekeeper_domain/core.dart';
import 'package:source_gen/source_gen.dart' as src;
import 'package:path/path.dart' as p;

import 'package:glob/glob.dart';

import 'common.dart';

/// Supports `package:build_runner` creation and configuration of
/// `json_serializable`.
///
/// Not meant to be invoked by hand-authored code.
Builder serializerGenerator(BuilderOptions options) {
  return SerializerDeserializerGenerator();
}

/// Check all @eventHandler annotated methods of @aggregate annotated classes.
/// This way we don't have to annotate or mark our events (keep them simple),
/// and we'll only support those that are actually being handled.
///
/// TODO: in the future, we might just have to support outgoing events as well,
///  but we can find them in @commandHandlers
class SerializerDeserializerGenerator implements Builder {

  static final _allFilesInLib = Glob('lib/src/**');

  static AssetId _allFileOutput(BuildStep buildStep) {
    return AssetId(
      buildStep.inputId.package,
      p.join('lib', 'src/serializer.s2.dart'),
    );
  }

  @override
  Map<String, List<String>> get buildExtensions {
    return const {
      r'$lib$': ['src/serializer.s2.dart']
    };
  }

  @override
  Future<void> build(BuildStep buildStep) async {
    final aggregates = <String>[];
    await for (final input in buildStep.findAssets(_allFilesInLib)) {
      final file = File(input.path);
      // Skip if the file does not exist (happens since the moor codegen stuff)
      if (!file.existsSync()) {
        break;
      }
      // Check if the file contains the @aggregate annotation
      final fileContent = file.readAsStringSync();
      if (fileContent.contains('@aggregate')) {
        // Aggregate = first instance of string between "class " and " extends" after "@aggregate" annotation
        final start = fileContent.indexOf('class ', fileContent.indexOf('@aggregate')) + 'class '.length;
        final end = fileContent.indexOf(' extends ', fileContent.indexOf('@aggregate'));
        final dtoBaseName = fileContent.substring(start, end);
        aggregates.add(dtoBaseName);
      }
    }


    // final imports = importedLibraries.fold('', (original, current) => "$original\nimport '$current';");
    final output = _allFileOutput(buildStep);
    return buildStep.writeAsString(output, DartFormatter().format('// TEST'));
  }

}
