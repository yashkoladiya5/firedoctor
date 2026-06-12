import 'package:test/test.dart';
import 'package:firedoctor/analyzers/dependency/firebase_package.dart';

void main() {
  group('FirebasePackage', () {
    group('all packages', () {
      test('core has correct packageName', () {
        expect(FirebasePackage.core.packageName, equals('firebase_core'));
      });

      test('auth has correct packageName', () {
        expect(FirebasePackage.auth.packageName, equals('firebase_auth'));
      });

      test('cloudFirestore has correct packageName', () {
        expect(
          FirebasePackage.cloudFirestore.packageName,
          equals('cloud_firestore'),
        );
      });

      test('storage has correct packageName', () {
        expect(FirebasePackage.storage.packageName, equals('firebase_storage'));
      });

      test('messaging has correct packageName', () {
        expect(
          FirebasePackage.messaging.packageName,
          equals('firebase_messaging'),
        );
      });

      test('crashlytics has correct packageName', () {
        expect(
          FirebasePackage.crashlytics.packageName,
          equals('firebase_crashlytics'),
        );
      });

      test('analytics has correct packageName', () {
        expect(
          FirebasePackage.analytics.packageName,
          equals('firebase_analytics'),
        );
      });

      test('remoteConfig has correct packageName', () {
        expect(
          FirebasePackage.remoteConfig.packageName,
          equals('firebase_remote_config'),
        );
      });

      test('database has correct packageName', () {
        expect(
          FirebasePackage.database.packageName,
          equals('firebase_database'),
        );
      });

      test('appCheck has correct packageName', () {
        expect(
          FirebasePackage.appCheck.packageName,
          equals('firebase_app_check'),
        );
      });
    });

    group('field values', () {
      for (final pkg in FirebasePackage.all) {
        test('${pkg.packageName} has non-empty displayName', () {
          expect(pkg.displayName, isNotEmpty);
        });

        test('${pkg.packageName} has non-empty category', () {
          expect(pkg.category, isNotEmpty);
        });

        test('${pkg.packageName} has non-empty documentationUrl', () {
          expect(pkg.documentationUrl, isNotEmpty);
        });

        test('${pkg.packageName} has non-empty description', () {
          expect(pkg.description, isNotEmpty);
        });
      }
    });

    group('all list', () {
      test('contains exactly 10 items', () {
        expect(FirebasePackage.all, hasLength(10));
      });

      test('contains all static instances', () {
        expect(
          FirebasePackage.all,
          containsAll([
            FirebasePackage.core,
            FirebasePackage.auth,
            FirebasePackage.cloudFirestore,
            FirebasePackage.storage,
            FirebasePackage.messaging,
            FirebasePackage.crashlytics,
            FirebasePackage.analytics,
            FirebasePackage.remoteConfig,
            FirebasePackage.database,
            FirebasePackage.appCheck,
          ]),
        );
      });
    });

    group('fromPackageName', () {
      test('returns core for firebase_core', () {
        expect(
          FirebasePackage.fromPackageName('firebase_core'),
          equals(FirebasePackage.core),
        );
      });

      test('returns auth for firebase_auth', () {
        expect(
          FirebasePackage.fromPackageName('firebase_auth'),
          equals(FirebasePackage.auth),
        );
      });

      test('returns cloudFirestore for cloud_firestore', () {
        expect(
          FirebasePackage.fromPackageName('cloud_firestore'),
          equals(FirebasePackage.cloudFirestore),
        );
      });

      test('returns storage for firebase_storage', () {
        expect(
          FirebasePackage.fromPackageName('firebase_storage'),
          equals(FirebasePackage.storage),
        );
      });

      test('returns messaging for firebase_messaging', () {
        expect(
          FirebasePackage.fromPackageName('firebase_messaging'),
          equals(FirebasePackage.messaging),
        );
      });

      test('returns crashlytics for firebase_crashlytics', () {
        expect(
          FirebasePackage.fromPackageName('firebase_crashlytics'),
          equals(FirebasePackage.crashlytics),
        );
      });

      test('returns analytics for firebase_analytics', () {
        expect(
          FirebasePackage.fromPackageName('firebase_analytics'),
          equals(FirebasePackage.analytics),
        );
      });

      test('returns remoteConfig for firebase_remote_config', () {
        expect(
          FirebasePackage.fromPackageName('firebase_remote_config'),
          equals(FirebasePackage.remoteConfig),
        );
      });

      test('returns database for firebase_database', () {
        expect(
          FirebasePackage.fromPackageName('firebase_database'),
          equals(FirebasePackage.database),
        );
      });

      test('returns appCheck for firebase_app_check', () {
        expect(
          FirebasePackage.fromPackageName('firebase_app_check'),
          equals(FirebasePackage.appCheck),
        );
      });

      test('returns null for unknown package', () {
        expect(FirebasePackage.fromPackageName('unknown_package'), isNull);
      });

      test('is case-sensitive', () {
        expect(FirebasePackage.fromPackageName('Firebase_Auth'), isNull);
      });
    });
  });
}
