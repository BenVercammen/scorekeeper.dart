
import 'dart:io';

import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:glob/glob.dart';
import 'package:path/path.dart' as p;
import 'package:scorekeeper_codegen/src/common.dart';
import 'package:scorekeeper_domain/core.dart';

/// Generate the serializer that we use for (de)serializing events
Builder serializerGenerator(BuilderOptions options) {
  return SerializerDeserializerGenerator();
}

/// TODO: Load the generated event classes and add methods for them...
class SerializerDeserializerGenerator implements Builder {

  static final _eventClassesFile = 'lib/src/generated/events.pb.dart';

  static AssetId _allFileOutput(BuildStep buildStep) {
    return AssetId(
      buildStep.inputId.package,
      p.join('lib', 'src/serializer.s.dart'),
    );
  }

  @override
  Map<String, List<String>> get buildExtensions {
    return const {
      r'$lib$': ['src/serializer.s.dart']
    };
  }

  /// Generate a Serializer and Deserializer class that handles all event classes
  /// defined in the (generated) ``events.pb.dart`` file.
  @override
  Future<void> build(BuildStep buildStep) async {
    // Prefix the (de)serializer with the "domain" name...
    var domainName = buildStep.inputId.package;
    domainName = domainName.substring(domainName.lastIndexOf('_') + 1);
    domainName = domainName.substring(0, 1).toUpperCase() + domainName.substring(1);
    final classes = <ClassElement>{};
    // Look for the events.pb.dart file
    await for (final assetId in buildStep.findAssets(Glob(_eventClassesFile))) {
      final file = File(assetId.path);
      // Skip if the file does not exist (happens since the moor codegen stuff)
      if (!file.existsSync()) {
        return;
      }
      // Resolve library...
      final lib = await buildStep.resolver.libraryFor(assetId, allowSyntaxErrors: false);
      // Classes uitlezen
      for (final element in lib.topLevelElements) {
        if (element is ClassElement) {
          classes.add(element as ClassElement);
        }
      }

      // Serializer
      final SerializerBuilder = ClassBuilder()
        ..name = '${domainName}Serializer'
        ..implements.add(Reference('DomainSerializer'))
        ..methods.add(_serializeMethod(classes));

      // Deserializer
      final eventHandlerBuilder = ClassBuilder()
        ..name = '${domainName}Deserializer'
        ..implements.add(Reference('DomainDeserializer'))
        ..methods.addAll({
            _deserializeMethod(classes),
            _deserializeAggregateIdMethod(classes)
            });

      // Import the correct packages/files/...
      final importedLibraries = getRelevantImports([...classes])
          // Add the core dependency
          ..add('package:scorekeeper_domain/core.dart')
          // Ignore protobuf...
          ..removeWhere((element) => element.contains('protobuf'));
      final imports = importedLibraries.fold('', (original, current) => "$original\nimport '$current';");
      // Put everything together!
      final emitter = DartEmitter();
      final serializer = SerializerBuilder.build().accept(emitter);
      final deserializer = eventHandlerBuilder.build().accept(emitter);
      final code = DartFormatter().format('$imports\n\n$serializer\n\n$deserializer');
      final output = _allFileOutput(buildStep);
      return buildStep.writeAsString(output, code);
    }
  }

  /// Build the serialize method
  Method _serializeMethod(Set<ClassElement> classes) {
    final builder = MethodBuilder()
      ..name = 'serialize'
      ..returns = const Reference('String')
      ..annotations.add(const Reference('override'));
    final param1 = ParameterBuilder()
      ..name = 'object'
      ..type = const Reference('dynamic');
    builder.requiredParameters.add(param1.build());
    final code = StringBuffer()
      ..write('switch (object.runtimeType) {')
      ..write("\n\tcase String:\n\t\treturn object.toString();");
    for (final classElement in classes) {
      code.write("\n\tcase ${classElement.name}:\n\t\treturn (object as ${classElement.name}).writeToJson();");
    }
    code
      ..write("\ndefault:\n\tthrow Exception('Cannot serialize \"\${object.runtimeType}\"');")
      ..write('}');
    builder.body = Code(code.toString());
    return builder.build();
  }

  /// Build the deserialize method
  Method _deserializeMethod(Set<ClassElement> classes) {
    final builder = MethodBuilder()
      ..name = 'deserialize'
      ..returns = const Reference('dynamic')
      ..annotations.add(const Reference('override'));
    final param1 = ParameterBuilder()
      ..name = 'payloadType'
      ..type = const Reference('String');
    final param2 = ParameterBuilder()
      ..name = 'serialized'
      ..type = const Reference('String');
    builder.requiredParameters.add(param1.build());
    builder.requiredParameters.add(param2.build());
    final code = StringBuffer()
      ..write('switch (payloadType) {')
      ..write("\n\tcase 'String':\n\t\treturn serialized;");
    for (final classElement in classes) {
      code.write("\n\tcase '${classElement.name}':\n\t\treturn ${classElement.name}.fromJson(serialized);");
    }
    code
      ..write("\ndefault:\n\tthrow Exception('Cannot deserialize \"\$payloadType\"');")
      ..write('}');
    builder.body = Code(code.toString());
    return builder.build();
  }

  /// Build the deserializeAggregateId method
  Method _deserializeAggregateIdMethod(Set<ClassElement> classes) {
    final builder = MethodBuilder()
      ..name = 'deserializeAggregateId'
      ..returns = const Reference('AggregateId')
      ..annotations.add(const Reference('override'));
    final param1 = ParameterBuilder()
      ..name = 'aggregateId'
      ..type = const Reference('String');
    final param2 = ParameterBuilder()
      ..name = 'aggregateType'
      ..type = const Reference('String');
    builder.requiredParameters.add(param1.build());
    builder.requiredParameters.add(param2.build());
    final code = StringBuffer()
      ..write('switch (aggregateType) {')
      ..write("\n\tcase 'String':\n\t\treturn AggregateId.of(aggregateId, String);");
    for (final classElement in classes) {
      code.write("\n\tcase '${classElement.name}':\n\t\treturn AggregateId.of(aggregateId, ${classElement.name});");
    }
    code
      ..write("\ndefault:\n\tthrow Exception('Cannot deserialize AggregateId for \"\$aggregateType\"');")
      ..write('}');
    builder.body = Code(code.toString());
    return builder.build();
  }

}
