
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
  generateForAnnotatedElement(Element element, src.ConstantReader annotation, BuildStep buildStep) {
    var aggregateName = element.name;

    if (element is! ClassElement) {
      throw src.InvalidGenerationSourceError(
        '`@aggregate` can only be used on classes.',
        element: element,
      );
    }

    ClassElement aggregate = element as ClassElement;
    ConstructorElement constructor = _getCommandHandlerConstructor(aggregate);
    List<MethodElement> commandHandlerMethods = _getHandlerMethods('commandHandler', aggregate);
    List<MethodElement> eventHandlerMethods = _getHandlerMethods('eventHandler', aggregate);

    // Command Handler
    var commandHandlerBuilder = ClassBuilder();
    commandHandlerBuilder.name = '${element.name}CommandHandler';
    commandHandlerBuilder.implements.add(Reference('CommandHandler<${element.name}>'));
    commandHandlerBuilder.methods.add(_commandIsConstructorMethod(constructor));
    commandHandlerBuilder.methods.add(_commandConstructorMethod(aggregate, constructor));
    commandHandlerBuilder.methods.add(_commandHandleMethod(aggregate, commandHandlerMethods));
    commandHandlerBuilder.methods.add(_newInstanceMethod(aggregate));
    commandHandlerBuilder.methods.add(_commandHandlesMethod(aggregate, constructor, commandHandlerMethods));

    // Event Handler
    var eventHandlerBuilder = ClassBuilder();
    eventHandlerBuilder.name = '${element.name}EventHandler';
    eventHandlerBuilder.implements.add(Reference('EventHandler<${element.name}>'));
    eventHandlerBuilder.methods.add(_eventHandleMethod(aggregate, eventHandlerMethods));
    eventHandlerBuilder.methods.add(_eventForTypeMethod(aggregate));
    eventHandlerBuilder.methods.add(_newInstanceMethod(aggregate));
    eventHandlerBuilder.methods.add(_eventHandlesMethod(aggregate, eventHandlerMethods));

    // Import the current aggregate package + scorekeeper_domain...
    var importedLibraries = <String>{};
    importedLibraries.add(element.library.identifier);
    importedLibraries.add('package:scorekeeper_domain/core.dart');

    var imports = importedLibraries.fold('', (original, current) => "$original\nimport '$current';");

    final emitter = DartEmitter();
    return DartFormatter().format('${imports}\n' +
        '\n${commandHandlerBuilder.build().accept(emitter)}\n' +
        '\n${eventHandlerBuilder.build().accept(emitter)}');
  }

  /// Build the handle method
  Method _commandHandleMethod(ClassElement aggregate, List<MethodElement> commandHandlerMethods) {
    var builder = MethodBuilder();
    builder.name = 'handle';
    builder.returns = Reference('void');
    var param1 = ParameterBuilder();
    param1.name = _camelName(aggregate.name);
    param1.type = Reference(aggregate.name);
    builder.requiredParameters.add(param1.build());
    var param2 = ParameterBuilder();
    param2.name = 'command';
    param2.type = Reference('dynamic');
    builder.requiredParameters.add(param2.build());

    String code = 'switch (command.runtimeType) {';
    commandHandlerMethods.forEach((handlerMethod) {
      var commandType = handlerMethod.parameters[0].type;
      code += '\ncase ${commandType.name}:\n\t${param1.name}.${handlerMethod.name}(command as ${commandType.name});';
      code += '\nreturn;';
    });
    code += "\ndefault:\n\tthrow Exception('Unsupported command \${command.runtimeType}.');";
    code += '}';
    builder.body = Code(code);

    builder.annotations.add(Reference('override'));
    return builder.build();
  }

  /// Build the handles method
  Method _commandHandlesMethod(ClassElement aggregate, ConstructorElement constructor, List<MethodElement> commandHandlerMethods) {
    var builder = MethodBuilder();
    builder.name = 'handles';
    builder.returns = Reference('bool');
    var param1 = ParameterBuilder();
    param1.name = 'command';
    param1.type = Reference('dynamic');
    builder.requiredParameters.add(param1.build());

    String code = 'switch (command.runtimeType) {';
    code += '\ncase ${constructor.parameters[0].type.name}:';
    commandHandlerMethods.forEach((handlerMethod) {
      var commandType = handlerMethod.parameters[0].type;
      code += '\ncase ${commandType.name}:';
    });
    code += '\nreturn true;';
    code += "\ndefault:\n\treturn false;";
    code += '}';
    builder.body = Code(code);

    builder.annotations.add(Reference('override'));
    return builder.build();
  }

  /// Build the handleConstructorCommand method
  Method _commandConstructorMethod(ClassElement aggregate, ConstructorElement commandConstructor) {
    var builder = MethodBuilder();
    builder.name = 'handleConstructorCommand';
    builder.returns = Reference(aggregate.name);
    var param1 = ParameterBuilder();
    param1.name = 'command';
    param1.type = Reference('dynamic');
    builder.requiredParameters.add(param1.build());
    var commandType = commandConstructor.parameters[0].type.name;
    builder.body = Code('return ${aggregate.name}.${commandConstructor.name}(command as ${commandType});');
    builder.annotations.add(Reference('override'));
    return builder.build();
  }

  /// Build the newInstance method
  Method _newInstanceMethod(ClassElement aggregate) {
    var builder = MethodBuilder();
    builder.name = 'newInstance';
    builder.returns = Reference(aggregate.name);
    var param1 = ParameterBuilder();
    param1.name = 'aggregateId';
    param1.type = Reference('AggregateId');
    builder.requiredParameters.add(param1.build());

    builder.body = Code('return ${aggregate.name}.aggregateId(aggregateId);');

    builder.annotations.add(Reference('override'));
    return builder.build();
  }

  /// Build the isConstructorCommand method
  Method _commandIsConstructorMethod(ConstructorElement constructor) {
    var builder = MethodBuilder();
    builder.name = 'isConstructorCommand';
    builder.returns = Reference('bool');
    var commandParam = ParameterBuilder();
    commandParam.name = 'command';
    commandParam.type = Reference('dynamic');
    builder.requiredParameters.add(commandParam.build());
    var constructorCommandParameterType = constructor.parameters[0].type.getDisplayString(withNullability: false);
    builder.body = Code('return command is ${constructorCommandParameterType};');
    builder.annotations.add(Reference('override'));
    return builder.build();
  }

  /// Get the (one and only) constructor command from the aggregate class
  ConstructorElement _getCommandHandlerConstructor(ClassElement aggregate) {
    var constructorCommands = aggregate.constructors.where((constructor) {
      var commandArguments = constructor.parameters.where((element) {
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
    var builder = MethodBuilder();
    builder.name = 'handles';
    builder.returns = Reference('bool');
    var param1 = ParameterBuilder();
    param1.name = 'event';
    param1.type = Reference('DomainEvent');
    builder.requiredParameters.add(param1.build());

    String code = 'switch (event.payload.runtimeType) {';
    commandHandlerMethods.forEach((handlerMethod) {
      var eventType = handlerMethod.parameters[0].type;
      code += '\ncase ${eventType.name}:';
    });
    code += '\nreturn true;';
    code += "\ndefault:\n\treturn false;";
    code += '}';
    builder.body = Code(code);

    builder.annotations.add(Reference('override'));
    return builder.build();
  }

  /// Build the handle method
  Method _eventHandleMethod(ClassElement aggregate, List<MethodElement> eventHandlerMethods) {
    var builder = MethodBuilder();
    builder.name = 'handle';
    builder.returns = Reference('void');
    var param1 = ParameterBuilder();
    param1.name = _camelName(aggregate.name);
    param1.type = Reference(aggregate.name);
    builder.requiredParameters.add(param1.build());
    var param2 = ParameterBuilder();
    param2.name = 'event';
    param2.type = Reference('DomainEvent');
    builder.requiredParameters.add(param2.build());

    String code = 'switch (event.payload.runtimeType) {';
    eventHandlerMethods.forEach((handlerMethod) {
      var eventType = handlerMethod.parameters[0].type;
      code += '\ncase ${eventType.name}:\n\t${param1.name}.${handlerMethod.name}(event.payload as ${eventType.name});';
      code += '\nreturn;';
    });
    code += "\ndefault:\n\tthrow Exception('Unsupported event \${event.payload.runtimeType}.');";
    code += '}';
    builder.body = Code(code);

    builder.annotations.add(Reference('override'));
    return builder.build();
  }

  /// Build the newInstance method
  Method _eventForTypeMethod(ClassElement aggregate) {
    var builder = MethodBuilder();
    builder.name = 'forType';
    builder.returns = Reference('bool');
    var param1 = ParameterBuilder();
    param1.name = 'type';
    param1.type = Reference('Type');
    builder.requiredParameters.add(param1.build());

    builder.body = Code('return type == ${aggregate.name};');

    builder.annotations.add(Reference('override'));
    return builder.build();
  }

  String _camelName(String name) => '${name[0].toLowerCase()}${name.substring(1)}';

  /// Get methods annotated with the given annotationName
  List<MethodElement> _getHandlerMethods(String annotationName, ClassElement aggregate) {
    var handlerMethods = aggregate.methods.where((method) {
      return method.metadata.where((meta) {
        return meta.element.name == annotationName;
      }).isNotEmpty;
    }).toList(growable: false);
    return handlerMethods;
  }


}
