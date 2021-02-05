
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:build/build.dart';
import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:scorekeeper_domain/core.dart';
import 'package:source_gen/source_gen.dart' as src;

import 'common.dart';

/// Supports `package:build_runner` creation and configuration of the AggregateDtoFactory.
///
/// Not meant to be invoked by hand-authored code.
Builder aggregateDtoFactoryGenerator(BuilderOptions options) {
  return src.LibraryBuilder(
      AggregateDtoFactoryGenerator(),
      generatedExtension: '.f.dart'
  );
}

class AggregateDtoFactoryGenerator extends src.GeneratorForAnnotation<AggregateAnnotation> {

  @override
  String generateForAnnotatedElement(Element element, src.ConstantReader annotation, BuildStep buildStep) {
    final aggregateName = element.name;

    if (element is! ClassElement) {
      throw src.InvalidGenerationSourceError(
        '`@aggregate` can only be used on classes.',
        element: element,
      );
    }

    final aggregate = element as ClassElement;

    // AggregateDtoFactory
    final factoryBuilder = ClassBuilder()
      ..name = 'AggregateDtoFactory'
      ..methods.add(_factoryCreateMethod([aggregate]))
    ;

    // AggregateDto
    final aggregateDtoBuilder = ClassBuilder()
      ..name = '${aggregateName}Dto'
      ..extend = refer('AggregateDto');
    // The only field this DTO will have, is a final, protected reference to the actual aggregate
    final aggregateFieldName = '_${_camelName(aggregateName)}';
    final fieldBuilder = FieldBuilder()
      ..name = aggregateFieldName
      ..type = Reference(aggregateName)
      ..modifier = FieldModifier.final$
    ;
    aggregateDtoBuilder.fields.add(fieldBuilder.build());
    // Constructor, private, taking only the aggregate
    final aggregateParam = ParameterBuilder()
      ..name = 'this.$aggregateFieldName';
    final constructorBuilder = ConstructorBuilder()
      ..name = '_'
      ..requiredParameters.add(aggregateParam.build())
      ..initializers.add(Code('super($aggregateFieldName.aggregateId)'));
    aggregateDtoBuilder.constructors.add(constructorBuilder.build());

    // All fields have to be converted to getters that will proxy the calls to the private aggregate instance
    final fields = getFilteredFields(aggregate, (field) => !field.name.startsWith('_'));
    for (var field in fields) {
      var body = Code('return $aggregateFieldName.${field.name};');
      // TODO: TEST!!! lists should become immutable copy...
      var returnType = field.type.element.name;
      if (returnType == 'List') {
        body = Code('return $returnType.of($aggregateFieldName.${field.name}, growable: false);');
        // If it's a parameterized type, make sure that gets included as well
        if (field.type is ParameterizedType) {
          final pType = field.type as ParameterizedType;
          if (!pType.typeArguments.isEmpty) {
            returnType += '<${pType.typeArguments[0].element.name}>';
          }
        }
      }
      final builder = MethodBuilder()
        ..name = field.name
        ..type = MethodType.getter
        ..returns = Reference(returnType)
        ..body = body
      ;
      aggregateDtoBuilder.methods.add(builder.build());
    }

    // Import the current aggregate package + scorekeeper_domain...
    final importedLibraries = getRelevantImports([aggregate, ...fields]);
    final imports = importedLibraries.fold('', (original, current) => "$original\nimport '$current';");
    // Put everything together!
    final emitter = DartEmitter();
    final aggregateDtoFactory = factoryBuilder.build().accept(emitter);
    final aggregateDto = aggregateDtoBuilder.build().accept(emitter);
    return DartFormatter().format('$imports\n\n$aggregateDtoFactory\n\n$aggregateDto');
  }

  String _camelName(String name) => '${name[0].toLowerCase()}${name.substring(1)}';

  Method _factoryCreateMethod(Iterable<ClassElement> aggregates) {
    final aggregateParam = ParameterBuilder()
      ..name = 'aggregate'
      ..type = const Reference('Aggregate');
    final code = StringBuffer()
      ..write('switch (aggregate.runtimeType) {');

    for (final aggregate in aggregates) {
      final varName = _camelName(aggregate.name);
      final varType = aggregate.name;
      code.write('\ncase $varType:\n\tfinal $varName = aggregate as $varType;\n\treturn ${varType}Dto._($varName) as R;');
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
