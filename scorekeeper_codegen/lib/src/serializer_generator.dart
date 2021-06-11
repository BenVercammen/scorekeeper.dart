
import 'dart:io';

import 'package:analyzer/dart/analysis/analysis_context.dart';
import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:build/build.dart';
import 'package:dart_style/dart_style.dart';
import 'package:glob/glob.dart';
import 'package:path/path.dart' as p;
import 'package:source_gen/source_gen.dart' as src;

/// Generate the serializer that we use for (de)serializing events
Builder serializerGenerator(BuilderOptions options) {
  return SerializerDeserializerGenerator();
}

/// TODO: Load the generated event classes and add methods for them...
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

  // TODO: deze blijft ook overeind, maar dus op basis van die generated event classes gaan werken??
  @override
  Future<void> build(BuildStep buildStep) async {
    final aggregates = <String>[];
    final inputIds = <AssetId>[];
    await for (final input in buildStep.findAssets(_allFilesInLib)) {
      final file = File(input.path);
      // Skip if the file does not exist (happens since the moor codegen stuff)
      if (!file.existsSync()) {
        continue;
      }
      // In case we have multiple "." characters, we're probably working with "part" files,
      // and the code below doesn't support that, so we try to filter them out already...
      if (file.path.indexOf('.') != file.path.lastIndexOf('.')) {
        continue;
      }
      // Check if the file contains the @aggregate annotation
      final fileContent = file.readAsStringSync();
      if (fileContent.contains('@aggregate')) {
        inputIds.add(input);
        // Aggregate = first instance of string between "class " and " extends" after "@aggregate" annotation
        final start = fileContent.indexOf(
            'class ', fileContent.indexOf('@aggregate')) + 'class '.length;
        final end = fileContent.indexOf(
            ' extends ', fileContent.indexOf('@aggregate'));
        final dtoBaseName = fileContent.substring(start, end);
        aggregates.add(dtoBaseName);
      }
    }

    // final imports = importedLibraries.fold('', (original, current) => "$original\nimport '$current';");
    final output = _allFileOutput(buildStep);

    return buildStep.writeAsString(output, DartFormatter().format(""));
  }

}


class _DummyAnnotation extends DartObject {
  @override
  DartObject? getField(String name) {
    // TODO: implement getField
    // throw UnimplementedError("// TODO: implement getField");
    return null;
  }

  @override
  // TODO: implement hasKnownValue
  bool get hasKnownValue => throw UnimplementedError("// TODO: implement hasKnownValue");

  @override
  // TODO: implement isNull
  bool get isNull => false; // throw UnimplementedError("// TODO: implement isNull");

  @override
  bool? toBoolValue() {
    // TODO: implement toBoolValue
    throw UnimplementedError("// TODO: implement toBoolValue");
  }

  @override
  double? toDoubleValue() {
    // TODO: implement toDoubleValue
    throw UnimplementedError("// TODO: implement toDoubleValue");
  }

  @override
  ExecutableElement? toFunctionValue() {
    // TODO: implement toFunctionValue
    throw UnimplementedError("// TODO: implement toFunctionValue");
  }

  @override
  int? toIntValue() {
    // TODO: implement toIntValue
    throw UnimplementedError("// TODO: implement toIntValue");
  }

  @override
  List<DartObject>? toListValue() {
    // TODO: implement toListValue
    throw UnimplementedError("// TODO: implement toListValue");
  }

  @override
  Map<DartObject?, DartObject?>? toMapValue() {
    // TODO: implement toMapValue
    throw UnimplementedError("// TODO: implement toMapValue");
  }

  @override
  Set<DartObject>? toSetValue() {
    // TODO: implement toSetValue
    throw UnimplementedError("// TODO: implement toSetValue");
  }

  @override
  String? toStringValue() {
    // TODO: implement toStringValue
    throw UnimplementedError("// TODO: implement toStringValue");
  }

  @override
  String? toSymbolValue() {
    // TODO: implement toSymbolValue
    throw UnimplementedError("// TODO: implement toSymbolValue");
  }

  @override
  DartType? toTypeValue() {
    // TODO: implement toTypeValue
    null; throw UnimplementedError("// TODO: implement toTypeValue");
  }

  @override
  // TODO: implement type
  ParameterizedType? get type => null; // throw UnimplementedError("// TODO: implement type");

}