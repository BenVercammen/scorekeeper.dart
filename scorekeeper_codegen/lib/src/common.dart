
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';


/// Generate a "camelCase" name for a given string.
/// Actually just lowercases the first character.
String camelName(String name) => '${name[0].toLowerCase()}${name.substring(1)}';

/// Get methods annotated with the given annotationName
/// Also grab annotated methods from super classes
List<MethodElement> getFilteredMethods(ClassElement element, bool Function(MethodElement method) methodFilterFunction) {
  if (element.name == 'Object') {
    return List.empty();
  }
  final handlerMethods = element.methods.where(methodFilterFunction).toList(growable: true);
  // Check super classes
  final superClass = getSuperClass(element);
  if (null != superClass) {
    handlerMethods.addAll(getFilteredMethods(superClass, methodFilterFunction));
  }
  return handlerMethods;
}

Iterable<FieldElement> getFilteredFields(ClassElement element, bool Function(FieldElement field) fieldFilterFunction, bool includeInheritedFields) {
  if (element.name == 'Object') {
    return List.empty();
  }
  final fields = List.of(element.fields.where(fieldFilterFunction).toList(growable: true), growable: true);
  // Check super classes
  if (includeInheritedFields) {
    final superClass = getSuperClass(element);
    if (null != superClass) {
      fields.addAll(getFilteredFields(superClass, fieldFilterFunction, includeInheritedFields));
    }
  }
  return fields;
}

/// Get the first superclass (if any)
ClassElement? getSuperClass(ClassElement aggregate) {
  try {
    return aggregate.allSupertypes
        .firstWhere((element) => element.element is ClassElement)
        .element;
    // ignore: avoid_catching_errors
  } on Error catch (_) {
    return null;
  }
}

/// Get the import statement that the (Class)Elements in the list refer to
Set<String> getRelevantImports(List<Element> list) {
  final fullImports = <String>{};
  for (final element in list) {
    // element.library?.imports.map((importElement) {
    //    return importElement.importedLibrary;
    // });
    // In case of inheritance, we'll also need to make sure to get the import for the parent class
    if (element is ClassElement) {
      final superclass = getSuperClass(element);
      if (null != superclass) {
        fullImports.add(superclass.library.identifier);
      }
    }
    // In case of method, make sure that we have imports for the parameter classes...
    if (element is MethodElement) {
      for (final parameter in element.parameters) {
        fullImports.add(parameter.type.element!.location!.components[0]);
      }
    }
    // In case of field, make sure that we have imports for typed parameter classes...
    if (element is FieldElement && element.type is InterfaceType) {
      for (final parameter in (element.type as InterfaceType).typeArguments) {
        fullImports.add(parameter.element!.location!.components[0]);
      }
    }
    final fullLibraryIdentifier = element.library!.identifier;
    fullImports.add(fullLibraryIdentifier);
  }
  return fullImports;
  //
  // final relativeImports = <String>{};
  // for (final fullLibraryIdentifier in fullImports.where((srcImport) => srcImport.contains('src/'))) {
  //   final relativeIdentifier = fullLibraryIdentifier.substring(fullLibraryIdentifier.lastIndexOf('/') + 1);
  //   for (final fullImport in fullImports.where((i) => !i.contains('src/') && i.startsWith('package:'))) {
  //     // Check if this full import file contains the relative path
  //     print(fullImport);
  //     // If so, remove the relative import from full imports and add the relative path...
  //
  //   }
  // }
  // // TODO: 2de run doen om reeds geimporteerde libraries te verwijderen??
  // //  De imports met "/src" moeten relatief worden!
  // return fullImports..addAll(relativeImports);
}
