import 'dart:io';

import 'package:flutter_project_builder/src/utils/file_utils.dart';
import 'package:flutter_project_builder/src/utils/native_project.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import 'helpers.dart';

/// Copies the real `flutter create` platform files from test/fixtures.
Directory nativeProject() {
  final project = createProject();
  final fixtures = Directory(p.join('test', 'fixtures', 'native'));
  for (final file in fixtures.listSync(recursive: true).whereType<File>()) {
    final target = File(
      p.join(project.path, p.relative(file.path, from: fixtures.path)),
    );
    target.parent.createSync(recursive: true);
    file.copySync(target.path);
  }
  return project;
}

void main() {
  late Directory project;
  late NativeProject native;

  setUp(() {
    project = nativeProject();
    native = NativeProject(projectPath: project.path, packageName: 'my_app');
  });

  group('applyOrganization', () {
    test('sets IDs on every platform', () {
      final result = native.applyOrganization('io.acme_labs');

      expect(
        readFile(project, 'android/app/build.gradle.kts'),
        contains('applicationId = "io.acme_labs.my_app"'),
      );
      expect(
        readFile(project, 'android/app/build.gradle.kts'),
        contains('namespace = "com.example.my_app"'),
        reason: 'the Kotlin package of MainActivity must not change',
      );
      final ios = readFile(project, 'ios/Runner.xcodeproj/project.pbxproj');
      expect(ios, contains('PRODUCT_BUNDLE_IDENTIFIER = io.acme-labs.myApp;'));
      expect(
        ios,
        contains('PRODUCT_BUNDLE_IDENTIFIER = io.acme-labs.myApp.RunnerTests;'),
      );
      expect(ios, isNot(contains('com.example')));
      expect(
        readFile(project, 'macos/Runner/Configs/AppInfo.xcconfig'),
        contains('PRODUCT_BUNDLE_IDENTIFIER = io.acme-labs.myApp'),
      );
      expect(
        readFile(project, 'linux/CMakeLists.txt'),
        contains('set(APPLICATION_ID "io.acme_labs.my_app")'),
      );
      expect(
        readFile(project, 'windows/runner/Runner.rc'),
        contains('"CompanyName", "io.acme_labs"'),
      );
      expect(result.changed, hasLength(6));
    });

    test('is idempotent', () {
      native.applyOrganization('io.acme');
      expect(native.applyOrganization('io.acme').changed, isEmpty);
    });
  });

  group('configureFlavors', () {
    test('adds Android product flavors and a flavored label', () {
      native.configureFlavors(['dev', 'prod']);
      final gradle = readFile(project, 'android/app/build.gradle.kts');

      expect(gradle, contains('flavorDimensions += "flavor"'));
      expect(gradle, contains('create("dev")'));
      expect(gradle, contains('applicationIdSuffix = ".dev"'));
      expect(
        gradle,
        contains('manifestPlaceholders["appName"] = "My App Dev"'),
      );
      expect(
        RegExp(r'create\("prod"\) \{[^}]*applicationIdSuffix').hasMatch(gradle),
        isFalse,
        reason: 'prod keeps the base application ID',
      );
      expect(
        gradle.indexOf('productFlavors'),
        greaterThan(gradle.indexOf('defaultConfig')),
      );
      expect(
        readFile(project, 'android/app/src/main/AndroidManifest.xml'),
        contains(r'android:label="${appName}"'),
      );
    });

    test('supports Groovy build files', () {
      File(p.join(project.path, 'android/app/build.gradle.kts')).deleteSync();
      File(p.join(project.path, 'android/app/build.gradle')).writeAsStringSync(
        'android {\n    defaultConfig {\n'
        '        applicationId "com.example.my_app"\n    }\n}\n',
      );
      native.configureFlavors(['qa']);
      final gradle = readFile(project, 'android/app/build.gradle');
      expect(gradle, contains('flavorDimensions "flavor"'));
      expect(gradle, contains('qa {'));
      expect(gradle, contains('applicationIdSuffix ".qa"'));
    });

    test('adds Xcode configurations, schemes and pod mappings', () {
      final result = native.configureFlavors(['dev', 'prod']);
      final pbxproj = readFile(project, 'ios/Runner.xcodeproj/project.pbxproj');

      for (final name in ['Debug-dev', 'Profile-dev', 'Release-prod']) {
        // One configuration per list: project, Runner and RunnerTests.
        expect(
          RegExp('name = $name;').allMatches(pbxproj),
          hasLength(3),
          reason: name,
        );
      }
      expect(
        pbxproj,
        contains('PRODUCT_BUNDLE_IDENTIFIER = com.example.myApp.dev;'),
      );
      expect(pbxproj, contains('APP_DISPLAY_NAME = "My App Dev";'));
      expect(
        readFile(project, 'ios/Runner/Info.plist'),
        contains(r'<string>$(APP_DISPLAY_NAME)</string>'),
      );

      final scheme = readFile(
        project,
        'ios/Runner.xcodeproj/xcshareddata/xcschemes/dev.xcscheme',
      );
      expect(scheme, contains('buildConfiguration = "Debug-dev"'));
      expect(scheme, contains('buildConfiguration = "Release-dev"'));
      expect(scheme, isNot(contains('buildConfiguration = "Debug"')));

      final podfile = readFile(project, 'ios/Podfile');
      expect(podfile, contains("'Debug-dev' => :debug,"));
      expect(podfile, contains("'Release-prod' => :release,"));

      // macOS also gets configurations for the Flutter Assemble target.
      final macos = readFile(project, 'macos/Runner.xcodeproj/project.pbxproj');
      expect(RegExp('name = Debug-dev;').allMatches(macos), hasLength(4));
      expect(
        macos,
        contains('PRODUCT_BUNDLE_IDENTIFIER = com.example.myApp.dev;'),
      );
      expect(
        result.changed,
        contains('macos/Runner.xcodeproj/project.pbxproj'),
      );
    });

    test('is idempotent and adds only new flavors later', () {
      native.configureFlavors(['dev', 'prod']);
      final second = native.configureFlavors(['dev', 'prod']);
      expect(second.changed, isEmpty);
      expect(second.warnings, isEmpty);

      final third = native.configureFlavors(['dev', 'prod', 'qa']);
      final pbxproj = readFile(project, 'ios/Runner.xcodeproj/project.pbxproj');
      expect(RegExp('name = Debug-dev;').allMatches(pbxproj), hasLength(3));
      expect(RegExp('name = Debug-qa;').allMatches(pbxproj), hasLength(3));
      expect(
        third.warnings.single,
        contains('add qa manually'),
        reason: 'existing Android productFlavors are not rewritten',
      );
    });

    test('skips missing platforms', () {
      Directory(p.join(project.path, 'ios')).deleteSync(recursive: true);
      Directory(p.join(project.path, 'macos')).deleteSync(recursive: true);
      final result = native.configureFlavors(['dev']);
      expect(result.changed, [
        'android/app/build.gradle.kts',
        'android/app/src/main/AndroidManifest.xml',
      ]);
    });

    test('writes nothing in a dry run', () async {
      final before = readFile(project, 'ios/Runner.xcodeproj/project.pbxproj');
      final recorder =
          await FileUtils.dryRun(() async => native.configureFlavors(['dev']));
      expect(
        readFile(project, 'ios/Runner.xcodeproj/project.pbxproj'),
        before,
      );
      expect(
        recorder.changes().keys.map(p.basename),
        containsAll(['project.pbxproj', 'dev.xcscheme', 'Podfile']),
      );
    });
  });

  group('raiseDeploymentTargets', () {
    test('raises lower targets and uncomments the Podfile platform', () {
      final pbxprojFile =
          File(p.join(project.path, 'ios/Runner.xcodeproj/project.pbxproj'));
      pbxprojFile.writeAsStringSync(
        pbxprojFile.readAsStringSync().replaceAll(
              'IPHONEOS_DEPLOYMENT_TARGET = 15.0;',
              'IPHONEOS_DEPLOYMENT_TARGET = 13.0;',
            ),
      );

      final result = native.raiseDeploymentTargets(ios: '15.0', macos: '10.15');

      expect(
        pbxprojFile.readAsStringSync(),
        isNot(contains('IPHONEOS_DEPLOYMENT_TARGET = 13.0;')),
      );
      expect(
        readFile(project, 'ios/Podfile'),
        contains("\nplatform :ios, '15.0'"),
      );
      expect(result.changed, contains('ios/Runner.xcodeproj/project.pbxproj'));
      expect(
        result.changed,
        isNot(contains('macos/Runner.xcodeproj/project.pbxproj')),
        reason: 'macOS is already at 10.15',
      );
    });

    test('never lowers a target', () {
      native.raiseDeploymentTargets(ios: '15.0');
      final before = readFile(project, 'ios/Runner.xcodeproj/project.pbxproj');
      native.raiseDeploymentTargets(ios: '12.0');
      expect(
        readFile(project, 'ios/Runner.xcodeproj/project.pbxproj'),
        before,
      );
      expect(
        readFile(project, 'ios/Podfile'),
        contains("platform :ios, '15.0'"),
      );
    });
  });
}
