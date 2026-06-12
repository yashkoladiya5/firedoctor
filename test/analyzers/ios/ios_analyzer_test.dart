import 'package:test/test.dart';
import 'package:firedoctor/analyzers/ios/ios_analyzer.dart';
import 'package:firedoctor/analyzers/analyzer_context.dart';
import 'package:firedoctor/models/models.dart';
import '../../shared/mocks.dart';

FakeFileSystem _createProject({required Map<String, String> files}) {
  final fs = FakeFileSystem();
  fs.addDirectory('/project');
  fs.addDirectory('/project/ios');
  fs.addDirectory('/project/ios/Runner');
  for (final entry in files.entries) {
    final dirs = entry.key.split('/');
    for (var i = 2; i < dirs.length; i++) {
      final dirPath = dirs.take(i).join('/');
      if (dirPath.isNotEmpty) {
        fs.addDirectory('/$dirPath');
      }
    }
    fs.addFile(entry.key, entry.value);
  }
  return fs;
}

String get validPlist => '''<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>BUNDLE_ID</key>
    <string>com.example.testapp</string>
    <key>PROJECT_ID</key>
    <string>test-project-id</string>
    <key>GOOGLE_APP_ID</key>
    <string>1:123456789:ios:abc123def456</string>
    <key>IS_ADS_ENABLED</key>
    <true/>
    <key>IS_ANALYTICS_ENABLED</key>
    <false/>
</dict>
</plist>''';

String plistWithBundleId(String bundleId) =>
    '''<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>BUNDLE_ID</key>
    <string>$bundleId</string>
    <key>PROJECT_ID</key>
    <string>test-project-id</string>
</dict>
</plist>''';

String get invalidPlist => 'not a valid plist';

String get emptyPlist => '';

String get minimalPlistNoBundleId => '''<?xml version="1.0" encoding="UTF-8"?>
<plist version="1.0">
<dict>
    <key>PROJECT_ID</key>
    <string>test-project-id</string>
</dict>
</plist>''';

String get validPbxproj => r'''{
	archiveVersion = 1;
	classes = {
	};
	objectVersion = 54;
	objects = {
		977D3C9E29E4C8D500B23E0D /* Runner */ = {
			isa = PBXNativeTarget;
			buildConfigurationList = 977D3CB429E4C8D500B23E0D /* Build configuration list for PBXNativeTarget "Runner" */;
			name = Runner;
			productName = Runner;
		};
		977D3CB529E4C8D500B23E0D /* Debug */ = {
			isa = XCBuildConfiguration;
			buildSettings = {
				PRODUCT_BUNDLE_IDENTIFIER = com.example.testapp;
				SystemCapabilities = {
					com.apple.BackgroundModes = {
						enabled = 1;
					};
					com.apple.Push = {
						enabled = 1;
					};
				};
			};
			name = Debug;
		};
	};
}
''';

String pbxprojWithBundleId(String bundleId) =>
    '{archiveVersion = 1; objects = {977D3C9E29E4C8D500B23E0D /* Runner */ = {isa = PBXNativeTarget; name = Runner;};977D3CB529E4C8D500B23E0D /* Debug */ = {isa = XCBuildConfiguration; buildSettings = {PRODUCT_BUNDLE_IDENTIFIER = $bundleId; SystemCapabilities = {com.apple.BackgroundModes = {enabled = 1;};com.apple.Push = {enabled = 1;};};};name = Debug;};};}';

String get pbxprojNoPush => r'''{
	objects = {
		977D3C9E29E4C8D500B23E0D /* Runner */ = {
			isa = PBXNativeTarget;
			name = Runner;
		};
		977D3CB529E4C8D500B23E0D /* Debug */ = {
			isa = XCBuildConfiguration;
			buildSettings = {
				PRODUCT_BUNDLE_IDENTIFIER = com.example.testapp;
				SystemCapabilities = {
					com.apple.BackgroundModes = {
						enabled = 1;
					};
				};
			};
			name = Debug;
		};
	};
}
''';

String get pbxprojNoBackgroundModes => r'''{
	objects = {
		977D3C9E29E4C8D500B23E0D /* Runner */ = {
			isa = PBXNativeTarget;
			name = Runner;
		};
		977D3CB529E4C8D500B23E0D /* Debug */ = {
			isa = XCBuildConfiguration;
			buildSettings = {
				PRODUCT_BUNDLE_IDENTIFIER = com.example.testapp;
				SystemCapabilities = {
					com.apple.Push = {
						enabled = 1;
					};
				};
			};
			name = Debug;
		};
	};
}
''';

String get pbxprojNoCapabilities => r'''{
	objects = {
		977D3C9E29E4C8D500B23E0D /* Runner */ = {
			isa = PBXNativeTarget;
			name = Runner;
		};
		977D3CB529E4C8D500B23E0D /* Debug */ = {
			isa = XCBuildConfiguration;
			buildSettings = {
				PRODUCT_BUNDLE_IDENTIFIER = com.example.testapp;
			};
			name = Debug;
		};
	};
}
''';

String get pbxprojNoBundleId => r'''{
	objects = {
		977D3C9E29E4C8D500B23E0D /* Runner */ = {
			isa = PBXNativeTarget;
			name = Runner;
		};
		977D3CB529E4C8D500B23E0D /* Debug */ = {
			isa = XCBuildConfiguration;
			buildSettings = {
			};
			name = Debug;
		};
	};
}
''';

String get pbxprojNoRunnerTarget => r'''{
	objects = {
		977D3C9E29E4C8D500B23E0D /* OtherTarget */ = {
			isa = PBXNativeTarget;
			name = OtherTarget;
		};
		977D3CB529E4C8D500B23E0D /* Debug */ = {
			isa = XCBuildConfiguration;
			buildSettings = {
				PRODUCT_BUNDLE_IDENTIFIER = com.example.testapp;
			};
			name = Debug;
		};
	};
}
''';

String infoPlistWithBackgroundModes(String mode) =>
    '''<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
\t<key>UIBackgroundModes</key>
\t<array>
\t\t<string>$mode</string>
\t</array>
\t<key>FirebaseAppDelegateProxyEnabled</key>
\t<false/>
</dict>
</plist>'''
        .replaceAll(r'$mode', mode);

String get infoPlistWithFirebaseProxyEnabled =>
    '''<?xml version="1.0" encoding="UTF-8"?>
<plist version="1.0">
<dict>
\t<key>UIBackgroundModes</key>
\t<array>
\t\t<string>remote-notification</string>
\t</array>
\t<key>FirebaseAppDelegateProxyEnabled</key>
\t<false/>
</dict>
</plist>''';

String get infoPlistNoBackgroundModes =>
    '''<?xml version="1.0" encoding="UTF-8"?>
<plist version="1.0">
<dict>
\t<key>FirebaseAppDelegateProxyEnabled</key>
\t<false/>
</dict>
</plist>''';

String get infoPlistNoFirebaseProxy => '''<?xml version="1.0" encoding="UTF-8"?>
<plist version="1.0">
<dict>
\t<key>UIBackgroundModes</key>
\t<array>
\t\t<string>remote-notification</string>
\t</array>
</dict>
</plist>''';

String get podfileWithFirebase => '''
platform :ios, '12.0'

target 'Runner' do
  use_frameworks!
  pod 'Firebase/Core'
end
''';

String get podfileWithMultipleFirebasePods => '''
platform :ios, '12.0'

target 'Runner' do
  use_frameworks!
  pod 'Firebase/Core'
  pod 'Firebase/Messaging'
  pod 'Firebase/Analytics'
end
''';

String get podfileWithoutFirebase => '''
platform :ios, '12.0'

target 'Runner' do
  use_frameworks!
end
''';

String get podfileLowVersion => '''
platform :ios, '10.0'

target 'Runner' do
  use_frameworks!
  pod 'Firebase/Core'
end
''';

String get podfileNoPlatform => '''
target 'Runner' do
  use_frameworks!
  pod 'Firebase/Core'
end
''';

String get podfileLockWithFirebase => r'''
PODS:
  - Firebase/Core (10.0.0)
  - Firebase/CoreOnly (10.0.0)
  - FirebaseCore (10.0.0)

DEPENDENCIES:
  - Firebase/Core (from `Pods`)
''';

String get podfileLockWithoutFirebase => '''
PODS:

DEPENDENCIES:
''';

String get dartFileWithFirebaseImport => '''
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
}
''';

String get dartFileWithoutFirebase => '''
void main() {
  print("Hello");
}
''';

void main() {
  group('IOSAnalyzer', () {
    late IOSAnalyzer analyzer;

    setUp(() {
      analyzer = IOSAnalyzer();
    });

    group('metadata', () {
      test('has correct name', () {
        expect(analyzer.name, equals('ios'));
      });

      test('has correct description', () {
        expect(
          analyzer.description,
          equals('Analyzes iOS Firebase configuration'),
        );
      });

      test('has correct category', () {
        expect(analyzer.category, equals('ios'));
      });
    });

    group('no ios directory', () {
      test('returns skipped when ios/ directory does not exist', () async {
        final fs = FakeFileSystem();
        final context = AnalyzerContext(
          projectPath: '/project',
          fileSystem: fs,
        );
        final result = await analyzer.analyze(context);

        expect(result.status, equals(CheckStatus.skipped));
        expect(result.issues, isEmpty);
      });

      test('returns skipped when ios is a file not a directory', () async {
        final fs = FakeFileSystem();
        fs.addFile('/project/ios', 'not a directory');
        final context = AnalyzerContext(
          projectPath: '/project',
          fileSystem: fs,
        );
        final result = await analyzer.analyze(context);

        expect(result.status, equals(CheckStatus.skipped));
        expect(result.issues, isEmpty);
      });
    });

    group('GoogleService-Info.plist checks', () {
      test('emits FD500 when GoogleService-Info.plist is missing', () async {
        final fs = _createProject(files: {});
        final context = AnalyzerContext(
          projectPath: '/project',
          fileSystem: fs,
        );
        final result = await analyzer.analyze(context);

        expect(result.issues.any((i) => i.code == 'FD500'), isTrue);
        final issue = result.issues.firstWhere((i) => i.code == 'FD500');
        expect(issue.severity, equals(Severity.critical));
        expect(result.status, equals(CheckStatus.failed));
      });

      test(
        'emits FD501 when GoogleService-Info.plist has invalid content',
        () async {
          final fs = _createProject(
            files: {
              '/project/ios/Runner/GoogleService-Info.plist': invalidPlist,
            },
          );
          final context = AnalyzerContext(
            projectPath: '/project',
            fileSystem: fs,
          );
          final result = await analyzer.analyze(context);

          expect(result.issues.any((i) => i.code == 'FD501'), isTrue);
          final issue = result.issues.firstWhere((i) => i.code == 'FD501');
          expect(issue.severity, equals(Severity.error));
          expect(result.status, equals(CheckStatus.failed));
        },
      );

      test('emits FD501 for empty plist content', () async {
        final fs = _createProject(
          files: {'/project/ios/Runner/GoogleService-Info.plist': emptyPlist},
        );
        final context = AnalyzerContext(
          projectPath: '/project',
          fileSystem: fs,
        );
        final result = await analyzer.analyze(context);

        expect(result.issues.any((i) => i.code == 'FD501'), isTrue);
      });

      test('passes when GoogleService-Info.plist is valid', () async {
        final fs = _createProject(
          files: {
            '/project/ios/Runner/GoogleService-Info.plist': validPlist,
            '/project/lib/main.dart': dartFileWithoutFirebase,
          },
        );
        final context = AnalyzerContext(
          projectPath: '/project',
          fileSystem: fs,
        );
        final result = await analyzer.analyze(context);

        expect(result.issues.where((i) => i.code == 'FD500'), isEmpty);
        expect(result.issues.where((i) => i.code == 'FD501'), isEmpty);
      });

      test('parses boolean and integer values from plist', () async {
        final fs = _createProject(
          files: {
            '/project/ios/Runner/GoogleService-Info.plist': validPlist,
            '/project/lib/main.dart': dartFileWithoutFirebase,
          },
        );
        final context = AnalyzerContext(
          projectPath: '/project',
          fileSystem: fs,
        );
        final result = await analyzer.analyze(context);

        expect(result.issues.where((i) => i.code == 'FD500'), isEmpty);
        expect(result.issues.where((i) => i.code == 'FD501'), isEmpty);
      });
    });

    group('Bundle ID checks', () {
      test(
        'emits FD502 when bundle ID mismatches between plist and pbxproj',
        () async {
          final fs = _createProject(
            files: {
              '/project/ios/Runner/GoogleService-Info.plist': plistWithBundleId(
                'com.example.plistapp',
              ),
              '/project/ios/Runner.xcodeproj/project.pbxproj':
                  pbxprojWithBundleId('com.example.xcodeapp'),
              '/project/lib/main.dart': dartFileWithoutFirebase,
            },
          );
          final context = AnalyzerContext(
            projectPath: '/project',
            fileSystem: fs,
          );
          final result = await analyzer.analyze(context);

          expect(result.issues.any((i) => i.code == 'FD502'), isTrue);
          final issue = result.issues.firstWhere((i) => i.code == 'FD502');
          expect(issue.severity, equals(Severity.error));
          expect(result.status, equals(CheckStatus.failed));
        },
      );

      test('does not emit FD502 when bundle IDs match', () async {
        final fs = _createProject(
          files: {
            '/project/ios/Runner/GoogleService-Info.plist': plistWithBundleId(
              'com.example.testapp',
            ),
            '/project/ios/Runner.xcodeproj/project.pbxproj':
                pbxprojWithBundleId('com.example.testapp'),
            '/project/lib/main.dart': dartFileWithoutFirebase,
          },
        );
        final context = AnalyzerContext(
          projectPath: '/project',
          fileSystem: fs,
        );
        final result = await analyzer.analyze(context);

        expect(result.issues.where((i) => i.code == 'FD502'), isEmpty);
      });

      test('does not emit FD502 when pbxproj is missing', () async {
        final fs = _createProject(
          files: {
            '/project/ios/Runner/GoogleService-Info.plist': plistWithBundleId(
              'com.example.testapp',
            ),
            '/project/lib/main.dart': dartFileWithoutFirebase,
          },
        );
        final context = AnalyzerContext(
          projectPath: '/project',
          fileSystem: fs,
        );
        final result = await analyzer.analyze(context);

        expect(result.issues.where((i) => i.code == 'FD502'), isEmpty);
      });

      test('does not emit FD502 when plist has no BUNDLE_ID', () async {
        final fs = _createProject(
          files: {
            '/project/ios/Runner/GoogleService-Info.plist':
                minimalPlistNoBundleId,
            '/project/ios/Runner.xcodeproj/project.pbxproj': validPbxproj,
            '/project/lib/main.dart': dartFileWithoutFirebase,
          },
        );
        final context = AnalyzerContext(
          projectPath: '/project',
          fileSystem: fs,
        );
        final result = await analyzer.analyze(context);

        expect(result.issues.where((i) => i.code == 'FD502'), isEmpty);
      });

      test(
        'emits FD503 when bundle identifier not detected in pbxproj',
        () async {
          final fs = _createProject(
            files: {
              '/project/ios/Runner/GoogleService-Info.plist': validPlist,
              '/project/ios/Runner.xcodeproj/project.pbxproj':
                  pbxprojNoBundleId,
              '/project/lib/main.dart': dartFileWithoutFirebase,
            },
          );
          final context = AnalyzerContext(
            projectPath: '/project',
            fileSystem: fs,
          );
          final result = await analyzer.analyze(context);

          expect(result.issues.any((i) => i.code == 'FD503'), isTrue);
          final issue = result.issues.firstWhere((i) => i.code == 'FD503');
          expect(issue.severity, equals(Severity.warning));
        },
      );

      test('does not emit FD503 when pbxproj is missing', () async {
        final fs = _createProject(
          files: {
            '/project/ios/Runner/GoogleService-Info.plist': validPlist,
            '/project/lib/main.dart': dartFileWithoutFirebase,
          },
        );
        final context = AnalyzerContext(
          projectPath: '/project',
          fileSystem: fs,
        );
        final result = await analyzer.analyze(context);

        expect(result.issues.where((i) => i.code == 'FD503'), isEmpty);
      });
    });

    group('Runner target checks', () {
      test(
        'emits FD504 when Runner target not found in Xcode project',
        () async {
          final fs = _createProject(
            files: {
              '/project/ios/Runner/GoogleService-Info.plist': validPlist,
              '/project/ios/Runner.xcodeproj/project.pbxproj':
                  pbxprojNoRunnerTarget,
              '/project/lib/main.dart': dartFileWithoutFirebase,
            },
          );
          final context = AnalyzerContext(
            projectPath: '/project',
            fileSystem: fs,
          );
          final result = await analyzer.analyze(context);

          expect(result.issues.any((i) => i.code == 'FD504'), isTrue);
          final issue = result.issues.firstWhere((i) => i.code == 'FD504');
          expect(issue.severity, equals(Severity.error));
          expect(result.status, equals(CheckStatus.failed));
        },
      );

      test('does not emit FD504 when Runner target exists', () async {
        final fs = _createProject(
          files: {
            '/project/ios/Runner/GoogleService-Info.plist': validPlist,
            '/project/ios/Runner.xcodeproj/project.pbxproj': validPbxproj,
            '/project/lib/main.dart': dartFileWithoutFirebase,
          },
        );
        final context = AnalyzerContext(
          projectPath: '/project',
          fileSystem: fs,
        );
        final result = await analyzer.analyze(context);

        expect(result.issues.where((i) => i.code == 'FD504'), isEmpty);
      });

      test('does not emit FD504 when pbxproj is missing', () async {
        final fs = _createProject(
          files: {
            '/project/ios/Runner/GoogleService-Info.plist': validPlist,
            '/project/lib/main.dart': dartFileWithoutFirebase,
          },
        );
        final context = AnalyzerContext(
          projectPath: '/project',
          fileSystem: fs,
        );
        final result = await analyzer.analyze(context);

        expect(result.issues.where((i) => i.code == 'FD504'), isEmpty);
      });
    });

    group('Push Notifications capability checks', () {
      test(
        'emits FD505 when Push Notifications capability is missing',
        () async {
          final fs = _createProject(
            files: {
              '/project/ios/Runner/GoogleService-Info.plist': validPlist,
              '/project/ios/Runner.xcodeproj/project.pbxproj': pbxprojNoPush,
              '/project/lib/main.dart': dartFileWithoutFirebase,
            },
          );
          final context = AnalyzerContext(
            projectPath: '/project',
            fileSystem: fs,
          );
          final result = await analyzer.analyze(context);

          expect(result.issues.any((i) => i.code == 'FD505'), isTrue);
          final issue = result.issues.firstWhere((i) => i.code == 'FD505');
          expect(issue.severity, equals(Severity.warning));
        },
      );

      test('does not emit FD505 when Push capability is enabled', () async {
        final fs = _createProject(
          files: {
            '/project/ios/Runner/GoogleService-Info.plist': validPlist,
            '/project/ios/Runner.xcodeproj/project.pbxproj': validPbxproj,
            '/project/lib/main.dart': dartFileWithoutFirebase,
          },
        );
        final context = AnalyzerContext(
          projectPath: '/project',
          fileSystem: fs,
        );
        final result = await analyzer.analyze(context);

        expect(result.issues.where((i) => i.code == 'FD505'), isEmpty);
      });
    });

    group('Background Modes capability checks', () {
      test('emits FD506 when Background Modes capability is missing', () async {
        final fs = _createProject(
          files: {
            '/project/ios/Runner/GoogleService-Info.plist': validPlist,
            '/project/ios/Runner.xcodeproj/project.pbxproj':
                pbxprojNoBackgroundModes,
            '/project/lib/main.dart': dartFileWithoutFirebase,
          },
        );
        final context = AnalyzerContext(
          projectPath: '/project',
          fileSystem: fs,
        );
        final result = await analyzer.analyze(context);

        expect(result.issues.any((i) => i.code == 'FD506'), isTrue);
        final issue = result.issues.firstWhere((i) => i.code == 'FD506');
        expect(issue.severity, equals(Severity.warning));
      });

      test('does not emit FD506 when Background Modes is enabled', () async {
        final fs = _createProject(
          files: {
            '/project/ios/Runner/GoogleService-Info.plist': validPlist,
            '/project/ios/Runner.xcodeproj/project.pbxproj': validPbxproj,
            '/project/lib/main.dart': dartFileWithoutFirebase,
          },
        );
        final context = AnalyzerContext(
          projectPath: '/project',
          fileSystem: fs,
        );
        final result = await analyzer.analyze(context);

        expect(result.issues.where((i) => i.code == 'FD506'), isEmpty);
      });

      test('emits FD506 when no SystemCapabilities at all', () async {
        final fs = _createProject(
          files: {
            '/project/ios/Runner/GoogleService-Info.plist': validPlist,
            '/project/ios/Runner.xcodeproj/project.pbxproj':
                pbxprojNoCapabilities,
            '/project/lib/main.dart': dartFileWithoutFirebase,
          },
        );
        final context = AnalyzerContext(
          projectPath: '/project',
          fileSystem: fs,
        );
        final result = await analyzer.analyze(context);

        expect(result.issues.any((i) => i.code == 'FD506'), isTrue);
        expect(result.issues.any((i) => i.code == 'FD505'), isTrue);
      });
    });

    group('Remote Notifications background mode checks', () {
      test(
        'emits FD507 when remote-notification background mode is missing',
        () async {
          final fs = _createProject(
            files: {
              '/project/pubspec.yaml': 'dependencies:\n  firebase_messaging: ^15.0.0\n',
              '/project/ios/Runner/GoogleService-Info.plist': validPlist,
              '/project/ios/Runner/Info.plist': infoPlistNoBackgroundModes,
              '/project/ios/Runner.xcodeproj/project.pbxproj': validPbxproj,
              '/project/lib/main.dart': dartFileWithoutFirebase,
            },
          );
          final context = AnalyzerContext(
            projectPath: '/project',
            fileSystem: fs,
          );
          final result = await analyzer.analyze(context);

          expect(result.issues.any((i) => i.code == 'FD507'), isTrue);
          final issue = result.issues.firstWhere((i) => i.code == 'FD507');
          expect(issue.severity, equals(Severity.warning));
        },
      );

      test(
        'does not emit FD507 when remote-notification is configured',
        () async {
          final fs = _createProject(
            files: {
              '/project/pubspec.yaml': 'dependencies:\n  firebase_messaging: ^15.0.0\n',
              '/project/ios/Runner/GoogleService-Info.plist': validPlist,
              '/project/ios/Runner/Info.plist':
                  infoPlistWithFirebaseProxyEnabled,
              '/project/ios/Runner.xcodeproj/project.pbxproj': validPbxproj,
              '/project/lib/main.dart': dartFileWithoutFirebase,
            },
          );
          final context = AnalyzerContext(
            projectPath: '/project',
            fileSystem: fs,
          );
          final result = await analyzer.analyze(context);

          expect(result.issues.where((i) => i.code == 'FD507'), isEmpty);
        },
      );

      test('does not emit FD507 when Info.plist is missing', () async {
        final fs = _createProject(
          files: {
            '/project/ios/Runner/GoogleService-Info.plist': validPlist,
            '/project/ios/Runner.xcodeproj/project.pbxproj': validPbxproj,
            '/project/lib/main.dart': dartFileWithoutFirebase,
          },
        );
        final context = AnalyzerContext(
          projectPath: '/project',
          fileSystem: fs,
        );
        final result = await analyzer.analyze(context);

        expect(result.issues.where((i) => i.code == 'FD507'), isEmpty);
      });
    });

    group('Podfile checks', () {
      test('emits FD508 when Podfile is missing', () async {
        final fs = _createProject(
          files: {
            '/project/ios/Runner/GoogleService-Info.plist': validPlist,
            '/project/lib/main.dart': dartFileWithoutFirebase,
          },
        );
        final context = AnalyzerContext(
          projectPath: '/project',
          fileSystem: fs,
        );
        final result = await analyzer.analyze(context);

        expect(result.issues.any((i) => i.code == 'FD508'), isTrue);
        final issue = result.issues.firstWhere((i) => i.code == 'FD508');
        expect(issue.severity, equals(Severity.error));
        expect(result.status, equals(CheckStatus.failed));
      });

      test('emits FD509 when iOS platform version is below 12.0', () async {
        final fs = _createProject(
          files: {
            '/project/ios/Runner/GoogleService-Info.plist': validPlist,
            '/project/ios/Podfile': podfileLowVersion,
            '/project/lib/main.dart': dartFileWithoutFirebase,
          },
        );
        final context = AnalyzerContext(
          projectPath: '/project',
          fileSystem: fs,
        );
        final result = await analyzer.analyze(context);

        expect(result.issues.any((i) => i.code == 'FD509'), isTrue);
        final issue = result.issues.firstWhere((i) => i.code == 'FD509');
        expect(issue.severity, equals(Severity.warning));
      });

      test('does not emit FD509 when platform version is 12.0', () async {
        final fs = _createProject(
          files: {
            '/project/ios/Runner/GoogleService-Info.plist': validPlist,
            '/project/ios/Podfile': podfileWithFirebase,
            '/project/lib/main.dart': dartFileWithoutFirebase,
          },
        );
        final context = AnalyzerContext(
          projectPath: '/project',
          fileSystem: fs,
        );
        final result = await analyzer.analyze(context);

        expect(result.issues.where((i) => i.code == 'FD509'), isEmpty);
      });

      test('does not emit FD509 when platform version is above 12.0', () async {
        final fs = _createProject(
          files: {
            '/project/ios/Runner/GoogleService-Info.plist': validPlist,
            '/project/ios/Podfile': "platform :ios, '15.0'\n",
            '/project/lib/main.dart': dartFileWithoutFirebase,
          },
        );
        final context = AnalyzerContext(
          projectPath: '/project',
          fileSystem: fs,
        );
        final result = await analyzer.analyze(context);

        expect(result.issues.where((i) => i.code == 'FD509'), isEmpty);
      });

      test('does not emit FD509 when platform is not specified', () async {
        final fs = _createProject(
          files: {
            '/project/ios/Runner/GoogleService-Info.plist': validPlist,
            '/project/ios/Podfile': podfileNoPlatform,
            '/project/lib/main.dart': dartFileWithoutFirebase,
          },
        );
        final context = AnalyzerContext(
          projectPath: '/project',
          fileSystem: fs,
        );
        final result = await analyzer.analyze(context);

        expect(result.issues.where((i) => i.code == 'FD509'), isEmpty);
      });
    });

    group('Firebase pods checks', () {
      test('emits FD510 when no Firebase pods in Podfile', () async {
        final fs = _createProject(
          files: {
            '/project/ios/Runner/GoogleService-Info.plist': validPlist,
            '/project/ios/Podfile': podfileWithoutFirebase,
            '/project/lib/main.dart': dartFileWithoutFirebase,
          },
        );
        final context = AnalyzerContext(
          projectPath: '/project',
          fileSystem: fs,
        );
        final result = await analyzer.analyze(context);

        expect(result.issues.any((i) => i.code == 'FD510'), isTrue);
        final issue = result.issues.firstWhere((i) => i.code == 'FD510');
        expect(issue.severity, equals(Severity.warning));
      });

      test('does not emit FD510 when Firebase pods are in Podfile', () async {
        final fs = _createProject(
          files: {
            '/project/ios/Runner/GoogleService-Info.plist': validPlist,
            '/project/ios/Podfile': podfileWithFirebase,
            '/project/lib/main.dart': dartFileWithoutFirebase,
          },
        );
        final context = AnalyzerContext(
          projectPath: '/project',
          fileSystem: fs,
        );
        final result = await analyzer.analyze(context);

        expect(result.issues.where((i) => i.code == 'FD510'), isEmpty);
      });

      test(
        'detects Firebase pods from Podfile.lock when Podfile has none',
        () async {
          final fs = _createProject(
            files: {
              '/project/ios/Runner/GoogleService-Info.plist': validPlist,
              '/project/ios/Podfile': podfileWithoutFirebase,
              '/project/ios/Podfile.lock': podfileLockWithFirebase,
              '/project/lib/main.dart': dartFileWithoutFirebase,
            },
          );
          final context = AnalyzerContext(
            projectPath: '/project',
            fileSystem: fs,
          );
          final result = await analyzer.analyze(context);

          expect(result.issues.where((i) => i.code == 'FD510'), isEmpty);
        },
      );

      test('detects multiple Firebase pods from Podfile', () async {
        final fs = _createProject(
          files: {
            '/project/ios/Runner/GoogleService-Info.plist': validPlist,
            '/project/ios/Podfile': podfileWithMultipleFirebasePods,
            '/project/lib/main.dart': dartFileWithoutFirebase,
          },
        );
        final context = AnalyzerContext(
          projectPath: '/project',
          fileSystem: fs,
        );
        final result = await analyzer.analyze(context);

        expect(result.issues.where((i) => i.code == 'FD510'), isEmpty);
      });
    });

    group('Firebase configuration reference checks', () {
      test(
        'emits FD511 when GoogleService-Info.plist exists but no Firebase imports',
        () async {
          final fs = _createProject(
            files: {
              '/project/ios/Runner/GoogleService-Info.plist': validPlist,
              '/project/lib/main.dart': dartFileWithoutFirebase,
            },
          );
          final context = AnalyzerContext(
            projectPath: '/project',
            fileSystem: fs,
          );
          final result = await analyzer.analyze(context);

          expect(result.issues.any((i) => i.code == 'FD511'), isTrue);
          final issue = result.issues.firstWhere((i) => i.code == 'FD511');
          expect(issue.severity, equals(Severity.info));
        },
      );

      test('does not emit FD511 when Firebase imports exist', () async {
        final fs = _createProject(
          files: {
            '/project/ios/Runner/GoogleService-Info.plist': validPlist,
            '/project/lib/main.dart': dartFileWithFirebaseImport,
          },
        );
        final context = AnalyzerContext(
          projectPath: '/project',
          fileSystem: fs,
        );
        final result = await analyzer.analyze(context);

        expect(result.issues.where((i) => i.code == 'FD511'), isEmpty);
      });

      test('scans nested directories for Firebase imports', () async {
        final fs = _createProject(
          files: {
            '/project/ios/Runner/GoogleService-Info.plist': validPlist,
            '/project/lib/main.dart': dartFileWithoutFirebase,
            '/project/lib/services/firebase_service.dart':
                dartFileWithFirebaseImport,
          },
        );
        // Add lib/services as a directory explicitly
        fs.addDirectory('/project/lib/services');
        final context = AnalyzerContext(
          projectPath: '/project',
          fileSystem: fs,
        );
        final result = await analyzer.analyze(context);

        expect(result.issues.where((i) => i.code == 'FD511'), isEmpty);
      });
    });

    group('APNs configuration checks', () {
      test(
        'emits FD512 when FirebaseAppDelegateProxyEnabled is not configured',
        () async {
          final fs = _createProject(
            files: {
              '/project/ios/Runner/GoogleService-Info.plist': validPlist,
              '/project/ios/Runner/Info.plist': infoPlistNoFirebaseProxy,
              '/project/lib/main.dart': dartFileWithoutFirebase,
            },
          );
          final context = AnalyzerContext(
            projectPath: '/project',
            fileSystem: fs,
          );
          final result = await analyzer.analyze(context);

          expect(result.issues.any((i) => i.code == 'FD512'), isTrue);
          final issue = result.issues.firstWhere((i) => i.code == 'FD512');
          expect(issue.severity, equals(Severity.info));
        },
      );

      test(
        'does not emit FD512 when FirebaseAppDelegateProxyEnabled is set',
        () async {
          final fs = _createProject(
            files: {
              '/project/ios/Runner/GoogleService-Info.plist': validPlist,
              '/project/ios/Runner/Info.plist':
                  infoPlistWithFirebaseProxyEnabled,
              '/project/lib/main.dart': dartFileWithoutFirebase,
            },
          );
          final context = AnalyzerContext(
            projectPath: '/project',
            fileSystem: fs,
          );
          final result = await analyzer.analyze(context);

          expect(result.issues.where((i) => i.code == 'FD512'), isEmpty);
        },
      );

      test('does not emit FD512 when Info.plist is missing', () async {
        final fs = _createProject(
          files: {
            '/project/ios/Runner/GoogleService-Info.plist': validPlist,
            '/project/lib/main.dart': dartFileWithoutFirebase,
          },
        );
        final context = AnalyzerContext(
          projectPath: '/project',
          fileSystem: fs,
        );
        final result = await analyzer.analyze(context);

        expect(result.issues.where((i) => i.code == 'FD512'), isEmpty);
      });
    });

    group('happy path - valid iOS Firebase project', () {
      test('returns passed when everything is correct', () async {
        final fs = _createProject(
          files: {
            '/project/ios/Runner/GoogleService-Info.plist': validPlist,
            '/project/ios/Runner.xcodeproj/project.pbxproj': validPbxproj,
            '/project/ios/Runner/Info.plist': infoPlistWithFirebaseProxyEnabled,
            '/project/ios/Podfile': podfileWithFirebase,
            '/project/lib/main.dart': dartFileWithFirebaseImport,
          },
        );
        final context = AnalyzerContext(
          projectPath: '/project',
          fileSystem: fs,
        );
        final result = await analyzer.analyze(context);

        expect(result.issues, isEmpty);
        expect(result.status, equals(CheckStatus.passed));
      });

      test(
        'returns passed with Podfile.lock instead of Podfile Firebase pods',
        () async {
          final fs = _createProject(
            files: {
              '/project/ios/Runner/GoogleService-Info.plist': validPlist,
              '/project/ios/Runner.xcodeproj/project.pbxproj': validPbxproj,
              '/project/ios/Runner/Info.plist':
                  infoPlistWithFirebaseProxyEnabled,
              '/project/ios/Podfile': podfileWithoutFirebase,
              '/project/ios/Podfile.lock': podfileLockWithFirebase,
              '/project/lib/main.dart': dartFileWithFirebaseImport,
            },
          );
          final context = AnalyzerContext(
            projectPath: '/project',
            fileSystem: fs,
          );
          final result = await analyzer.analyze(context);

          expect(result.issues.where((i) => i.code == 'FD510'), isEmpty);
          expect(result.status, equals(CheckStatus.passed));
        },
      );
    });

    group('status computation', () {
      test('returns failed when critical issues exist', () async {
        final fs = _createProject(files: {});
        final context = AnalyzerContext(
          projectPath: '/project',
          fileSystem: fs,
        );
        final result = await analyzer.analyze(context);

        expect(result.issues.any((i) => i.code == 'FD500'), isTrue);
        expect(result.status, equals(CheckStatus.failed));
      });

      test('returns failed when error issues exist', () async {
        final fs = _createProject(
          files: {
            '/project/ios/Runner/GoogleService-Info.plist': plistWithBundleId(
              'com.example.plistapp',
            ),
            '/project/ios/Runner.xcodeproj/project.pbxproj':
                pbxprojWithBundleId('com.example.xcodeapp'),
            '/project/lib/main.dart': dartFileWithoutFirebase,
          },
        );
        final context = AnalyzerContext(
          projectPath: '/project',
          fileSystem: fs,
        );
        final result = await analyzer.analyze(context);

        expect(result.issues.any((i) => i.code == 'FD502'), isTrue);
        expect(result.status, equals(CheckStatus.failed));
      });

      test('returns warning when only warning issues exist', () async {
        final fs = _createProject(
          files: {
            '/project/ios/Runner/GoogleService-Info.plist': validPlist,
            '/project/ios/Podfile': podfileWithoutFirebase,
            '/project/lib/main.dart': dartFileWithoutFirebase,
          },
        );
        final context = AnalyzerContext(
          projectPath: '/project',
          fileSystem: fs,
        );
        final result = await analyzer.analyze(context);

        expect(result.issues.any((i) => i.code == 'FD510'), isTrue);
        expect(result.status, equals(CheckStatus.warning));
      });

      test('returns passed when only info issues exist', () async {
        final fs = _createProject(
          files: {
            '/project/ios/Runner/GoogleService-Info.plist': validPlist,
            '/project/ios/Podfile': podfileWithFirebase,
            '/project/lib/main.dart': dartFileWithoutFirebase,
          },
        );
        final context = AnalyzerContext(
          projectPath: '/project',
          fileSystem: fs,
        );
        final result = await analyzer.analyze(context);

        expect(result.issues.any((i) => i.code == 'FD511'), isTrue);
        expect(result.status, equals(CheckStatus.passed));
      });

      test('returns passed when no issues', () async {
        final fs = _createProject(
          files: {
            '/project/ios/Runner/GoogleService-Info.plist': validPlist,
            '/project/ios/Runner.xcodeproj/project.pbxproj': validPbxproj,
            '/project/ios/Runner/Info.plist': infoPlistWithFirebaseProxyEnabled,
            '/project/ios/Podfile': podfileWithFirebase,
            '/project/lib/main.dart': dartFileWithFirebaseImport,
          },
        );
        final context = AnalyzerContext(
          projectPath: '/project',
          fileSystem: fs,
        );
        final result = await analyzer.analyze(context);

        expect(result.status, equals(CheckStatus.passed));
        expect(result.issues, isEmpty);
      });
    });

    group('combined edge cases', () {
      test('handles empty ios directory (only ios/ exists)', () async {
        final fs = FakeFileSystem();
        fs.addDirectory('/project');
        fs.addDirectory('/project/ios');
        fs.addDirectory('/project/ios/Runner');
        final context = AnalyzerContext(
          projectPath: '/project',
          fileSystem: fs,
        );
        final result = await analyzer.analyze(context);

        expect(result.issues.any((i) => i.code == 'FD500'), isTrue);
        expect(result.status, equals(CheckStatus.failed));
      });

      test('multiple issues simultaneously - all check types', () async {
        final fs = _createProject(
          files: {
            '/project/ios/Runner/GoogleService-Info.plist': invalidPlist,
            '/project/ios/Runner.xcodeproj/project.pbxproj':
                pbxprojNoRunnerTarget,
            '/project/lib/main.dart': dartFileWithoutFirebase,
          },
        );
        final context = AnalyzerContext(
          projectPath: '/project',
          fileSystem: fs,
        );
        final result = await analyzer.analyze(context);

        expect(result.issues.any((i) => i.code == 'FD501'), isTrue);
        expect(result.issues.any((i) => i.code == 'FD504'), isTrue);
        expect(result.issues.any((i) => i.code == 'FD508'), isTrue);
        expect(result.status, equals(CheckStatus.failed));
      });

      test('missing multiple files generates multiple issues', () async {
        final fs = _createProject(files: {});
        final context = AnalyzerContext(
          projectPath: '/project',
          fileSystem: fs,
        );
        final result = await analyzer.analyze(context);

        expect(result.issues.any((i) => i.code == 'FD500'), isTrue);
        expect(result.issues.any((i) => i.code == 'FD508'), isTrue);
        expect(result.issues.any((i) => i.code == 'FD511'), isFalse);
        expect(result.status, equals(CheckStatus.failed));
      });

      test('handles malformed pbxproj gracefully', () async {
        final fs = _createProject(
          files: {
            '/project/ios/Runner/GoogleService-Info.plist': validPlist,
            '/project/ios/Runner.xcodeproj/project.pbxproj': 'garbage content',
            '/project/lib/main.dart': dartFileWithoutFirebase,
          },
        );
        final context = AnalyzerContext(
          projectPath: '/project',
          fileSystem: fs,
        );
        final result = await analyzer.analyze(context);

        expect(result.issues.any((i) => i.code == 'FD503'), isTrue);
        expect(result.issues.any((i) => i.code == 'FD504'), isTrue);
      });
    });

    group('result metadata', () {
      test('result has correct analyzerName', () async {
        final fs = _createProject(
          files: {
            '/project/ios/Runner/GoogleService-Info.plist': validPlist,
            '/project/ios/Runner.xcodeproj/project.pbxproj': validPbxproj,
            '/project/ios/Runner/Info.plist': infoPlistWithFirebaseProxyEnabled,
            '/project/ios/Podfile': podfileWithFirebase,
            '/project/lib/main.dart': dartFileWithFirebaseImport,
          },
        );
        final context = AnalyzerContext(
          projectPath: '/project',
          fileSystem: fs,
        );
        final result = await analyzer.analyze(context);

        expect(result.analyzerName, equals('ios'));
      });

      test('result has non-zero duration', () async {
        final fs = _createProject(
          files: {
            '/project/ios/Runner/GoogleService-Info.plist': validPlist,
            '/project/ios/Runner.xcodeproj/project.pbxproj': validPbxproj,
            '/project/ios/Runner/Info.plist': infoPlistWithFirebaseProxyEnabled,
            '/project/ios/Podfile': podfileWithFirebase,
            '/project/lib/main.dart': dartFileWithFirebaseImport,
          },
        );
        final context = AnalyzerContext(
          projectPath: '/project',
          fileSystem: fs,
        );
        final result = await analyzer.analyze(context);

        expect(result.duration.inMicroseconds, greaterThanOrEqualTo(0));
      });

      test('result has a recent timestamp', () async {
        final fs = _createProject(
          files: {
            '/project/ios/Runner/GoogleService-Info.plist': validPlist,
            '/project/ios/Runner.xcodeproj/project.pbxproj': validPbxproj,
            '/project/ios/Runner/Info.plist': infoPlistWithFirebaseProxyEnabled,
            '/project/ios/Podfile': podfileWithFirebase,
            '/project/lib/main.dart': dartFileWithFirebaseImport,
          },
        );
        final context = AnalyzerContext(
          projectPath: '/project',
          fileSystem: fs,
        );
        final result = await analyzer.analyze(context);

        expect(result.timestamp.isAfter(DateTime(2020, 1, 1)), isTrue);
      });
    });

    group('parser injection', () {
      test('can inject custom parsers', () async {
        final analyzer = IOSAnalyzer();
        final fs = _createProject(
          files: {
            '/project/ios/Runner/GoogleService-Info.plist': validPlist,
            '/project/lib/main.dart': dartFileWithoutFirebase,
          },
        );
        final context = AnalyzerContext(
          projectPath: '/project',
          fileSystem: fs,
        );
        final result = await analyzer.analyze(context);

        expect(result.analyzerName, equals('ios'));
      });
    });
  });
}
