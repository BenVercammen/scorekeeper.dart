
import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:scorekeeper_domain/core.dart';
import 'package:source_gen/source_gen.dart' as src;


/// Supports `package:build_runner` creation and configuration of
/// `json_serializable`.
///
/// Not meant to be invoked by hand-authored code.
Builder handlerGenerator(BuilderOptions options) {
  return src.LibraryBuilder(
    CommandEventHandlerGenerator()
    ,
    // 'json_serializable',
    // formatOutput: true,
  );
}


class CommandEventHandlerGenerator extends src.GeneratorForAnnotation<AggregateAnnotation> {

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
    final constructor = _getCommandHandlerConstructor(aggregate);
    final commandHandlerMethods = _getHandlerMethods('commandHandler', aggregate);
    final eventHandlerMethods = _getHandlerMethods('eventHandler', aggregate);

    // Command Handler
    final commandHandlerBuilder = ClassBuilder()
      ..name = '${aggregateName}CommandHandler'
      ..implements.add(Reference('CommandHandler<$aggregateName>'))
      ..methods.add(_commandIsConstructorMethod(constructor))
      ..methods.add(_commandConstructorMethod(aggregate, constructor))
      ..methods.add(_commandHandleMethod(aggregate, commandHandlerMethods))
      ..methods.add(_newInstanceMethod(aggregate))
      ..methods.add(_commandHandlesMethod(aggregate, constructor, commandHandlerMethods));

    // Event Handler
    final eventHandlerBuilder = ClassBuilder()
      ..name = '${aggregateName}EventHandler'
      ..implements.add(Reference('EventHandler<$aggregateName>'))
      ..methods.add(_eventHandleMethod(aggregate, eventHandlerMethods))
      ..methods.add(_eventForTypeMethod(aggregate))
      ..methods.add(_newInstanceMethod(aggregate))
      ..methods.add(_eventHandlesMethod(aggregate, eventHandlerMethods));

    // Import the current aggregate package + scorekeeper_domain...
    final importedLibraries = <String>{}
      ..add(element.library.identifier)
      ..add('package:scorekeeper_domain/core.dart');

    final imports = importedLibraries.fold('', (original, current) => "$original\nimport '$current';");

    final emitter = DartEmitter();
    return DartFormatter().format('$imports\n' +
        '\n${commandHandlerBuilder.build().accept(emitter)}\n' +
        '\n${eventHandlerBuilder.build().accept(emitter)}');
  }

  /// Build the handle method
  Method _commandHandleMethod(ClassElement aggregate, List<MethodElement> commandHandlerMethods) {
    final builder = MethodBuilder()
      ..name = 'handle'
      ..returns = const Reference('void');
    final param1 = ParameterBuilder()
      ..name = _camelName(aggregate.name)
      ..type = Reference(aggregate.name);
    builder.requiredParameters.add(param1.build());
    final param2 = ParameterBuilder()
      ..name = 'command'
      ..type = const Reference('dynamic');
    builder.requiredParameters.add(param2.build());

    var code = 'switch (command.runtimeType) {';
    commandHandlerMethods.forEach((handlerMethod) {
      final commandType = handlerMethod.parameters[0].type;
      code += '\ncase ${commandType.name}:\n\t${param1.name}.${handlerMethod.name}(command as ${commandType.name});';
      code += '\nreturn;';
    });
    code += "\ndefault:\n\tthrow Exception('Unsupported command \${command.runtimeType}.');";
    code += '}';
    builder.body = Code(code);

    builder.annotations.add(const Reference('override'));
    return builder.build();
  }

  /// Build the handles method
  Method _commandHandlesMethod(ClassElement aggregate, ConstructorElement constructor, List<MethodElement> commandHandlerMethods) {
    final builder = MethodBuilder()
      ..name = 'handles'
      ..returns = const Reference('bool');
    final param1 = ParameterBuilder()
      ..name = 'command'
      ..type = const Reference('dynamic');
    builder.requiredParameters.add(param1.build());

    var code = 'switch (command.runtimeType) {';
    code += '\ncase ${constructor.parameters[0].type.name}:';
    commandHandlerMethods.forEach((handlerMethod) {
      final commandType = handlerMethod.parameters[0].type;
      code += '\ncase ${commandType.name}:';
    });
    code += '\nreturn true;';
    code += '\ndefault:\n\treturn false;';
    code += '}';
    builder.body = Code(code);

    builder.annotations.add(const Reference('override'));
    return builder.build();
  }

  /// Build the handleConstructorCommand method
  Method _commandConstructorMethod(ClassElement aggregate, ConstructorElement commandConstructor) {
    final builder = MethodBuilder()
      ..name = 'handleConstructorCommand'
      ..returns = Reference(aggregate.name);
    final param1 = ParameterBuilder()
      ..name = 'command'
      ..type = const Reference('dynamic');
    builder.requiredParameters.add(param1.build());
    final commandType = commandConstructor.parameters[0].type.name;
    builder.body = Code('return ${aggregate.name}.${commandConstructor.name}(command as $commandType);');
    builder.annotations.add(const Reference('override'));
    return builder.build();
  }

  /// Build the newInstance method
  Method _newInstanceMethod(ClassElement aggregate) {
    final builder = MethodBuilder()
      ..name = 'newInstance'
      ..returns = Reference(aggregate.name);
    final param1 = ParameterBuilder()
      ..name = 'aggregateId'
      ..type = const Reference('AggregateId');
    builder.requiredParameters.add(param1.build());
    builder.body = Code('return ${aggregate.name}.aggregateId(aggregateId);');
    builder.annotations.add(const Reference('override'));
    return builder.build();
  }

  /// Build the isConstructorCommand method
  Method _commandIsConstructorMethod(ConstructorElement constructor) {
    final builder = MethodBuilder()
      ..name = 'isConstructorCommand'
      ..returns = const Reference('bool');
    final commandParam = ParameterBuilder()
      ..name = 'command'
      ..type = const Reference('dynamic');
    builder.requiredParameters.add(commandParam.build());
    final constructorCommandParameterType = constructor.parameters[0].type.getDisplayString(withNullability: false);
    builder.body = Code('return command is $constructorCommandParameterType;');
    builder.annotations.add(const Reference('override'));
    return builder.build();
  }

  /// Get the (one and only) constructor command from the aggregate class
  ConstructorElement _getCommandHandlerConstructor(ClassElement aggregate) {
    final constructorCommands = aggregate.constructors.where((constructor) {
      final commandArguments = constructor.parameters.where((element) {
        // Voor constructor moet de parameter "command" noemen (sinds we geen annotaties gebruiken)
        return 'command' == element.name;
      }).toList();
      return commandArguments.isNotEmpty;
    }).toList();
    if (constructorCommands.isEmpty) {
      throw Exception('No constructor command handlers were found. Add at least one with a "command" parameter');
    }
    if (constructorCommands.length > 1) {
      throw Exception('Too many constructor command handlers were found. There can be only one!');
    }
    return constructorCommands.first;
  }


  /// Build the handles method
  Method _eventHandlesMethod(ClassElement aggregate, List<MethodElement> commandHandlerMethods) {
    final builder = MethodBuilder()
      ..name = 'handles'
      ..returns = const Reference('bool');
    final param1 = ParameterBuilder()
      ..name = 'event'
      ..type = const Reference('DomainEvent');
    builder.requiredParameters.add(param1.build());
    var code = 'switch (event.payload.runtimeType) {';
    commandHandlerMethods.forEach((handlerMethod) {
      final eventType = handlerMethod.parameters[0].type;
      code += '\ncase ${eventType.name}:';
    });
    code += '\nreturn true;';
    code += '\ndefault:\n\treturn false;';
    code += '}';
    builder.body = Code(code);
    builder.annotations.add(const Reference('override'));
    return builder.build();
  }

  /// Build the handle method
  Method _eventHandleMethod(ClassElement aggregate, List<MethodElement> eventHandlerMethods) {
    final builder = MethodBuilder()
      ..name = 'handle'
      ..returns = const Reference('void');
    final param1 = ParameterBuilder()
      ..name = _camelName(aggregate.name)
      ..type = Reference(aggregate.name);
    builder.requiredParameters.add(param1.build());
    final param2 = ParameterBuilder()
      ..name = 'event'
      ..type = const Reference('DomainEvent');
    builder.requiredParameters.add(param2.build());

    var code = 'switch (event.payload.runtimeType) {';
    eventHandlerMethods.forEach((handlerMethod) {
      final eventType = handlerMethod.parameters[0].type;
      code += '\ncase ${eventType.name}:\n\t${param1.name}.${handlerMethod.name}(event.payload as ${eventType.name});';
      code += '\nreturn;';
    });
    code += "\ndefault:\n\tthrow Exception('Unsupported event \${event.payload.runtimeType}.');";
    code += '}';
    builder.body = Code(code);

    builder.annotations.add(const Reference('override'));
    return builder.build();
  }

  /// Build the newInstance method
  Method _eventForTypeMethod(ClassElement aggregate) {
    final builder = MethodBuilder()
      ..name = 'forType'
      ..returns = const Reference('bool');
    final param1 = ParameterBuilder()
      ..name = 'type'
      ..type = const Reference('Type');
    builder.requiredParameters.add(param1.build());
    builder.body = Code('return type == ${aggregate.name};');
    builder.annotations.add(const Reference('override'));
    return builder.build();
  }

  String _camelName(String name) => '${name[0].toLowerCase()}${name.substring(1)}';

  /// Get methods annotated with the given annotationName
  List<MethodElement> _getHandlerMethods(String annotationName, ClassElement aggregate) {
    final handlerMethods = aggregate.methods.where((method) {
      return method.metadata.where((meta) {
        return meta.element.name == annotationName;
      }).isNotEmpty;
    }).toList(growable: false);
    return handlerMethods;
  }


}
