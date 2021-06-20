
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:build/build.dart';
// ignore: import_of_legacy_library_into_null_safe
import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:scorekeeper_domain/core.dart';
import 'package:source_gen/source_gen.dart' as src;

import 'common.dart';

/// Supports `package:build_runner` creation and configuration of the AggregateDtoFactory.
///
/// Not meant to be invoked by hand-authored code.
Builder aggregateDtoGenerator(BuilderOptions options) {
  return src.LibraryBuilder(
      AggregateDtoGenerator(),
      generatedExtension: '.d.dart'
  );
}

/// Generate the AggregateDto, following the inheritance structure of the actual Aggregate.
class AggregateDtoGenerator extends src.GeneratorForAnnotation<AggregateAnnotation> {

  @override
  String generateForAnnotatedElement(Element element, src.ConstantReader annotation, BuildStep buildStep) {
    final aggregateName = element.name;
    // Only for ClassElement
    if (element is! ClassElement) {
      throw src.InvalidGenerationSourceError(
        '`@aggregate` can only be used on classes.',
        element: element,
      );
    }

    final aggregate = element;

    // AggregateDto
    final parentDtoClass = getSuperClass(aggregate);
    final aggregateDtoBuilder = ClassBuilder()
      ..name = '${aggregateName}Dto'
      ..extend = refer('${parentDtoClass!.name}Dto')
    ;
    // The only field this DTO will have, is a final, protected reference to the actual aggregate
    final aggregateFieldName = '_${camelName(aggregateName!)}';
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
      ..name = null
      ..requiredParameters.add(aggregateParam.build())
      ..initializers.add(Code('super($aggregateFieldName)'));
    aggregateDtoBuilder.constructors.add(constructorBuilder.build());

    // All fields have to be converted to getters that will proxy the calls to the private aggregate instance
    final fields = getFilteredFields(aggregate, (field) => !field.name.startsWith('_'), false);
    for (var field in fields) {
      var body = Code('return $aggregateFieldName.${field.name};');
      // TODO: TEST!!! lists should become immutable copy...
      var returnType = field.type.element?.name;
      if (returnType == 'List') {
        body = Code('return $returnType.of($aggregateFieldName.${field.name}, growable: false);');
      }
      // If it's a parameterized type, make sure that gets included as well
      if (null != returnType) {
        if (field.type is ParameterizedType) {
          final pType = field.type as ParameterizedType;
          if (pType.typeArguments.isNotEmpty) {
            final typeNames = pType.typeArguments.map((t) => t.element?.name);
            returnType += '<${typeNames.join(', ')}>';
          }
        }
      } else {
        returnType = 'Void';
      }
      final builder = MethodBuilder()
        ..name = field.name
        ..type = MethodType.getter
        ..returns = Reference(returnType)
        ..body = body
      ;

      // TODO: equals, hashcode en tostring methodes ook genereren?

      aggregateDtoBuilder.methods.add(builder.build());
    }

    // AggregateId
    // const aggregateIdClassName = 'AggregateId';
    // final aggregateIdBuilder = ClassBuilder()
    //   ..name = aggregateIdClassName
    //   ..extend = refer(parentDtoClass.name == 'Aggregate' ? 'AggregateId' : '${parentDtoClass.name}AggregateId')
    // ;
    //
    // final fieldBuilder2 = FieldBuilder()
    //   ..name = camelName(aggregateIdClassName)
    //   ..type = Reference(aggregateIdClassName)
    //   ..modifier = FieldModifier.final$
    // ;
    // aggregateIdBuilder.fields.add(fieldBuilder2.build());
    //
    // // Constructors
    // final constr1Param = ParameterBuilder()
    //   ..name = 'this.${camelName(aggregateIdClassName)}';
    // final constrBuilder1 = ConstructorBuilder()
    //   ..requiredParameters.add(constr1Param.build())
    // ;
    // In case we extend an Aggregate subclass, make sure to correctly initialize the constructor
    final isSubclassed = element.supertype?.element.name != 'Aggregate';
    // if (isSubclassed) {
    //   constrBuilder1.initializers.add(Code('super(${camelName(aggregateIdClassName)})'));
    // }
    // aggregateIdBuilder.constructors.add(constrBuilder1.build());
    //
    // final constr2Param = ParameterBuilder()
    //   ..name = 'id'
    //   ..type = const Reference('String');
    //
    // if (!isSubclassed) {
    //   final constrBuilder2 = ConstructorBuilder()
    //     ..name = '_'
    //     ..requiredParameters.add(constr2Param.build())
    //     ..initializers.add(
    //         Code('${camelName(aggregateIdClassName)} = ${aggregateIdClassName}(uuid: id)'))
    //   ;
    //   aggregateIdBuilder.constructors.add(constrBuilder2.build());
    // }
    //
    // final methodOf = MethodBuilder()
    //   ..name = 'of'
    //   ..returns = Reference(aggregateIdClassName)
    //   ..static = true
    //   ..requiredParameters.add(constr2Param.build())
    //   ..body = Code('return $aggregateIdClassName._(id);')
    // ;
    // if (isSubclassed) {
    //   methodOf.body = Code('return $aggregateIdClassName($aggregateIdClassName(uuid: id));');
    // }
    // aggregateIdBuilder.methods.add(methodOf.build());
    //
    // final methodRandom = MethodBuilder()
    //   ..name = 'random'
    //   ..returns = Reference(aggregateIdClassName)
    //   ..static = true
    //   ..body = Code('return $aggregateIdClassName._(const Uuid().v4());')
    // ;
    // if (isSubclassed) {
    //   methodRandom.body = Code('return $aggregateIdClassName($aggregateIdClassName(uuid: const Uuid().v4()));');
    // }
    // aggregateIdBuilder.methods.add(methodRandom.build());
    //
    // final getType = MethodBuilder()
    //   ..name = 'type'
    //   ..type = MethodType.getter
    //   ..returns = const Reference('Type')
    //   ..lambda = true
    //   ..body = Code(aggregateName)
    //   ..annotations.add(const Reference('override'))
    // ;
    // aggregateIdBuilder.methods.add(getType.build());
    //
    // final getId = MethodBuilder()
    //   ..name = 'id'
    //   ..type = MethodType.getter
    //   ..returns = const Reference('String')
    //   ..lambda = true
    //   ..body = Code('${camelName(aggregateIdClassName)}.uuid')
    //   ..annotations.add(const Reference('override'))
    // ;
    // aggregateIdBuilder.methods.add(getId.build());

    // Import the current aggregate package + scorekeeper_domain if necessary...
    var importedLibraries = getRelevantImports([...fields])
    ..add('package:uuid/uuid.dart');
    if (!isSubclassed) {
      importedLibraries.add('package:scorekeeper_domain/core.dart');
    }
    // In case we are inheriting from another generated parent AggregateDto class, we'll have to jump some hoops to add the import
    if ('Aggregate' != parentDtoClass.name) {
      importedLibraries = {...importedLibraries, parentDtoClass.library.identifier.replaceAll('dart', 'd.dart')};
    } else {
      importedLibraries = {...importedLibraries, 'package:scorekeeper_domain/core.dart'};
    }
    final imports = importedLibraries.fold('', (original, current) => "$original\nimport '$current';");

    // Put everything together!
    final emitter = DartEmitter();
    final aggregateDto = aggregateDtoBuilder.build().accept(emitter);
    // final aggregateId = aggregateIdBuilder.build().accept(emitter);
    return DartFormatter().format('$imports\n\n$aggregateDto');
  }

}
