
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
      CommandEventHandlerGenerator(),
      generatedExtension: '.h.dart'
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
    // Collect input for the handler methods
    final aggregate = element as ClassElement;
    final constructor = _getCommandHandlerConstructor(aggregate);
    final commandHandlerMethods = _getHandlerMethods('commandHandler', aggregate);
    final eventHandlerMethods = _getHandlerMethods('eventHandler', aggregate);

    // Keep track of the imported libraries
    final importedLibraries = <String>{}
      ..add('package:scorekeeper_domain/core.dart')
      ..addAll(_getRelevantImports([aggregate, ...commandHandlerMethods, ...eventHandlerMethods]))
    ;

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
    final imports = importedLibraries.fold('', (original, current) => "$original\nimport '$current';");
    // Put everything together!
    final emitter = DartEmitter();
    final commandHandler = commandHandlerBuilder.build().accept(emitter);
    final eventHandler = eventHandlerBuilder.build().accept(emitter);
    return DartFormatter().format('$imports\n\n$commandHandler\n\n$eventHandler');
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
    final code = StringBuffer()
      ..write('switch (command.runtimeType) {');
    for (final handlerMethod in commandHandlerMethods) {
      final commandType = handlerMethod.parameters[0].type;
      code.write('\ncase ${commandType.element.name}:\n\t${param1.name}.${handlerMethod.name}(command as ${commandType.element.name});\nreturn;');
    }
    code.write("\ndefault:\n\tthrow Exception('Unsupported command \${command.runtimeType}.');\n}");
    builder.body = Code(code.toString());
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
    final code = StringBuffer()
      ..write('switch (command.runtimeType) {')
      ..write('\ncase ${constructor.parameters[0].type.element.name}:');
    for (var handlerMethod in commandHandlerMethods) {
      final commandType = handlerMethod.parameters[0].type;
      code.write('\ncase ${commandType.element.name}:');
    }
    code
      ..write('\nreturn true;')
      ..write('\ndefault:\n\treturn false;')
      ..write('}');
    builder.body = Code(code.toString());
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
    final commandType = commandConstructor.parameters[0].type.element.name;
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
  /// We'll first look into the given aggregate class, but if there's nothing there,
  /// we'll see if we can get any of the parent's constructor command handlers.
  ConstructorElement _getCommandHandlerConstructor(ClassElement aggregate) {
    final constructorCommands = aggregate.constructors.where((constructor) {
      final commandArguments = constructor.parameters.where((element) {
        // Voor constructor moet de parameter "command" noemen (sinds we geen annotaties gebruiken)
        return 'command' == element.name;
      }).toList();
      return commandArguments.isNotEmpty;
    }).toList();
    if (constructorCommands.length > 1) {
      throw Exception('Too many constructor command handlers were found. There can be only one!');
    }
    if (constructorCommands.isEmpty) {
      // Note that we cannot just refer to the parent class constructor,
      // so guess we'll have to require each subclass to have a dedicated command constructor
      // final superClass = _getSuperClass(aggregate);
      // if (null == superClass) {
        throw Exception('No constructor command handlers were found. Add at least one constructor with a "command" parameter');
      // } else {
      //   return _getCommandHandlerConstructor(superClass as ClassElement);
      // }
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
    final code = StringBuffer()
      ..write('switch (event.payload.runtimeType) {');
    for (var handlerMethod in commandHandlerMethods) {
      final eventType = handlerMethod.parameters[0].type;
      code.write('\ncase ${eventType.element.name}:');
    }
    code..write('\nreturn true;')
      ..write('\ndefault:\n\treturn false;')
      ..write('}');
    builder.body = Code(code.toString());
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
    final code = StringBuffer()
      ..write('switch (event.payload.runtimeType) {');
    for (var handlerMethod in eventHandlerMethods) {
      final eventType = handlerMethod.parameters[0].type;
      code
        ..write('\ncase ${eventType.element.name}:\n\t${param1.name}.${handlerMethod.name}(event.payload as ${eventType.element.name});')
        ..write('\nreturn;');
    }
    code
      ..write("\ndefault:\n\tthrow Exception('Unsupported event \${event.payload.runtimeType}.');")
      ..write('}');
    builder.body = Code(code.toString());
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
  /// Also grab annotated methods from super classes
  List<MethodElement> _getHandlerMethods(String annotationName, ClassElement aggregate) {
    final handlerMethods = aggregate.methods.where((method) {
      return method.metadata.where((meta) {
        return meta.element.name == annotationName;
      }).isNotEmpty;
    }).toList(growable: true);
    // Check super classes
    final superClass = _getSuperClass(aggregate);
    if (null != superClass) {
      handlerMethods.addAll(_getHandlerMethods(annotationName, superClass));
    }
    return handlerMethods;
  }

  /// Get the first superclass (if any)
  ClassElement _getSuperClass(ClassElement aggregate) {
    try {
      return aggregate.allSupertypes
          ?.firstWhere((element) => element.element is ClassElement)
          ?.element;
    // ignore: avoid_catching_errors
    } on Error catch (_) {
      return null;
    }
  }

  /// Get the import statement that refers to the
  Iterable<String> _getRelevantImports(List<Element> list) {
    final imports = <String>{};
    for (final element in list) {
      final fullLibraryIdentifier = element.library.identifier;
      final relativeIdentifier = fullLibraryIdentifier.substring(fullLibraryIdentifier.lastIndexOf('/') + 1);
      imports.add(relativeIdentifier);
    }
    return imports;
  }


}
