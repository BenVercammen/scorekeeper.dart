import 'dart:io';

import 'package:build/build.dart';
// ignore: import_of_legacy_library_into_null_safe
import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:glob/glob.dart';
import 'package:path/path.dart' as p;

import 'common.dart';

/// Supports `package:build_runner` creation and configuration of the AggregateDtoFactory.
///
/// Not meant to be invoked by hand-authored code.
Builder aggregateDtoFactoryGenerator(BuilderOptions options) {
  return AggregateDtoFactoryGenerator();
}

class AggregateDtoFactoryGenerator implements Builder {
  static final _allFilesInLib = Glob('lib/src/**');

  static AssetId _allFileOutput(BuildStep buildStep) {
    return AssetId(
      buildStep.inputId.package,
      p.join('lib', 'src/aggregate.f.dart'),
    );
  }

  @override
  Map<String, List<String>> get buildExtensions {
    return const {
      r'$lib$': ['src/aggregate.f.dart']
    };
  }

  /// Collect all AggregateDto constructors into a single factory class.
  /// TODO: would like to do something similar to the Annotation based builder, but I need it all in a single file... :/
  ///  So the issue now is that I don't have any "analyzer Element classes" at my disposal, and have to do things hard-codedly
  ///
  /// Renders something like this:
  ///
  ///   import 'package:scorekeeper_domain/core.dart';
  ///   import 'package:scorekeeper_example_domain/example.dart';
  ///
  ///   class AggregateDtoFactory {
  ///     static R create<R extends AggregateDto>(Aggregate aggregate) {
  ///       switch (aggregate.runtimeType) {
  ///         case Scorable:
  ///           final scorable = aggregate as Scorable;
  ///           return ScorableDto(scorable) as R;
  ///         case MuurkeKlopNDown:
  ///           final muurkeKlopNDown = aggregate as MuurkeKlopNDown;
  ///           return MuurkeKlopNDownDto(muurkeKlopNDown) as R;
  ///         default:
  ///           throw Exception('Cannot create $R for ${aggregate.runtimeType}');
  ///       }
  ///     }
  ///   }
  @override
  Future<void> build(BuildStep buildStep) async {
    final aggregates = <String>[];
    await for (final input in buildStep.findAssets(_allFilesInLib)) {
      // Check if the file contains the @aggregate annotation
      final fileContent = File(input.path).readAsStringSync();
      if (fileContent.contains('@aggregate')) {
        // Aggregate = first instance of string between "class " and " extends" after "@aggregate" annotation
        final start = fileContent.indexOf('class ', fileContent.indexOf('@aggregate')) + 'class '.length;
        final end = fileContent.indexOf(' extends ', fileContent.indexOf('@aggregate'));
        final dtoBaseName = fileContent.substring(start, end);
        aggregates.add(dtoBaseName);
      }
    }
    final createMethod = _factoryCreateMethod(aggregates);
    final classBuilder = ClassBuilder()
      ..name = 'AggregateDtoFactory'
      ..methods.add(createMethod);
    final emitter = DartEmitter();
    final aggregateDtoFactory = classBuilder.build().accept(emitter);

    // global import
    final importedLibraries = {'package:scorekeeper_domain/core.dart'};
    await for (final file in buildStep.findAssets(Glob('lib/*.dart'))) {
      final fileContents = File(file.path).readAsStringSync();
      if (fileContents.contains('library ')) {
        final import = 'package:${file.package}/${file.pathSegments.last}';
        importedLibraries.add(import);
      }
    }

    final imports = importedLibraries.fold('', (original, current) => "$original\nimport '$current';");
    final output = _allFileOutput(buildStep);
    return buildStep.writeAsString(output, DartFormatter().format('$imports\n\n$aggregateDtoFactory'));
  }

  Method _factoryCreateMethod(Iterable<String> aggregates) {
    final aggregateParam = ParameterBuilder()
      ..name = 'aggregate'
      ..type = const Reference('Aggregate');
    final code = StringBuffer()..write('switch (aggregate.runtimeType) {');

    for (final aggregate in aggregates) {
      final varName = camelName(aggregate);
      final varType = aggregate;
      code.write('\ncase $varType:\n\tfinal $varName = aggregate as $varType;\n\treturn ${varType}Dto($varName) as R;');
    }
    code.write("\ndefault:\n\tthrow Exception('Cannot create \$R for \${aggregate.runtimeType}');\n}");
    final builder = MethodBuilder()
      ..name = 'create'
      ..returns = const Reference('R')
      ..static = true
      ..types.add(const Reference('R extends AggregateDto'))
      ..requiredParameters.add(aggregateParam.build())
      ..body = Code(code.toString());
    return builder.build();
  }
}
