
import 'dart:io';

import 'package:analyzer/dart/analysis/analysis_context.dart';
import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:build/build.dart';
import 'package:dart_style/dart_style.dart';
import 'package:glob/glob.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:json_serializable/json_serializable.dart';
// import 'package:json_serializable/json_serializable.dart';
import 'package:path/path.dart' as p;
import 'package:source_gen/source_gen.dart' as src;

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

    /// TODO: eigenlijk alle @eventHandlers afgaan, daar de types van opzoeken,
    ///  en DIE door de @JsonSerializable code generation jagen...
    /// TODO: da's via "json_serializable_generator"
    ///   -> dan komt het er wel nog op aan om een ClassElement / annotation
    // final serializer = JsonSerializableGenerator.withDefaultHelpers([]);
    // final source = StringSource()
    // final context = ContextBuilderImpl();
    // TODO: buildStep.inputId == $lib$ stuff, en dat is niet OKE hier... moet echt ne file hebben!?
      // eg: scorekeeper_example_domain|lib/src/muurkeklop.dart
    var generatedCode = '';
    for (final inputId in inputIds) {
      // try {
        final lib = await buildStep.resolver
            .libraryFor(inputId, allowSyntaxErrors: false);

        // Eerst proberen een annotated class element te pakken te krijgen die we kunnen meegeven met generator...
        final generator = JsonSerializableGenerator.withDefaultHelpers([]);

// TODO        final annotation = lib.topLevelElements.where((element) => element.).typeChecker.firstAnnotationOf(element, throwOnUnresolved: true);

      // final aggregateAnnotation = lib.topLevelElements.first.declaration!.metadata.first;
      //   generator.typeChecker.annotationsOf(lib.topLevelElements.elementAt(0));
//        final annotation = generator.typeChecker.firstAnnotationOf(lib.topLevelElements.first.declaration!, throwOnUnresolved: true);
        // We gaan serializers maken voor alle classes in de .e.dart file!!
        for (final element in lib.topLevelElements) {
          final eventClassPart = element.location!
              .components
              .where((l) => l.toString().contains('.e.dart'));
          if (eventClassPart.isNotEmpty) {
            if (element is ClassElement) {
              // TODO: fuckerij, nog steeds die annotation nodig, grrrrrrrrr

              // element.declaration.metadata.add(ElementAnnotation()JsonSerializable())
              final annotation = generator.typeChecker.firstAnnotationOf(lib.topLevelElements.first.declaration!, throwOnUnresolved: true);


              // element.declaration.metadata
              print("SERIALIZE :::: ${element.name}");
              // final annotation = generator.typeChecker.firstAnnotationOf(element, throwOnUnresolved: true);
              // final annotation = _DummyAnnotation();
              final code = generator.generateForAnnotatedElement(
                  element, src.ConstantReader(annotation), buildStep);
              for (final line in code) {
                generatedCode += line;
              }
            }
          }
        }
      // } on Exception catch (e) {
      //   print(e);
      // } on Error catch (e) {
      //   print(e);
      // }
      // Element element = null;
      // src.ConstantReader annotation = null;
      // final result = serializer.generateForAnnotatedElement(element, annotation, buildStep);
    }
    // final imports = importedLibraries.fold('', (original, current) => "$original\nimport '$current';");
    final output = _allFileOutput(buildStep);

    return buildStep.writeAsString(output, DartFormatter().format(generatedCode));
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