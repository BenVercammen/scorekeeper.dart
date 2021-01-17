
@TestOn('vm')
@Tags(['presubmit-only'])
import 'package:build_verify/build_verify.dart';
import 'package:test/test.dart';

/// Verify that generated Dart code within this package is up-to-date when using package:build.
void main() {
  test('ensure_build', () => expectBuildClean(packageRelativeDirectory: 'scorekeeper_example_domain'));
}
