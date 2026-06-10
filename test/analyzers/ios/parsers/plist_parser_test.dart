import 'package:test/test.dart';
import 'package:firedoctor/analyzers/ios/parsers/plist_parser.dart';

void main() {
  group('PlistParser', () {
    late PlistParser parser;

    setUp(() {
      parser = const PlistParser();
    });

    group('parseGoogleServiceInfoPlist', () {
      test('returns null for empty content', () {
        final result = parser.parseGoogleServiceInfoPlist('');
        expect(result, isNull);
      });

      test('returns null for whitespace-only content', () {
        final result = parser.parseGoogleServiceInfoPlist('   \n  \t  ');
        expect(result, isNull);
      });

      test('returns null for content without plist tags', () {
        final result = parser.parseGoogleServiceInfoPlist('just random text');
        expect(result, isNull);
      });

      test('returns null for content without dict', () {
        final result = parser.parseGoogleServiceInfoPlist('<plist version="1.0"></plist>');
        expect(result, isNull);
      });

      test('returns null for empty dict', () {
        final result = parser.parseGoogleServiceInfoPlist('<plist><dict></dict></plist>');
        expect(result, isNull);
      });

      test('parses string values from plist', () {
        final result = parser.parseGoogleServiceInfoPlist('''<plist version="1.0">
<dict>
    <key>BUNDLE_ID</key>
    <string>com.example.test</string>
    <key>PROJECT_ID</key>
    <string>my-project</string>
</dict>
</plist>''');
        expect(result, isNotNull);
        expect(result!['BUNDLE_ID'], equals('com.example.test'));
        expect(result['PROJECT_ID'], equals('my-project'));
      });

      test('parses true boolean values', () {
        final result = parser.parseGoogleServiceInfoPlist('''<plist version="1.0">
<dict>
    <key>IS_ADS_ENABLED</key>
    <true/>
</dict>
</plist>''');
        expect(result, isNotNull);
        expect(result!['IS_ADS_ENABLED'], equals('true'));
      });

      test('parses false boolean values', () {
        final result = parser.parseGoogleServiceInfoPlist('''<plist version="1.0">
<dict>
    <key>IS_ANALYTICS_ENABLED</key>
    <false/>
</dict>
</plist>''');
        expect(result, isNotNull);
        expect(result!['IS_ANALYTICS_ENABLED'], equals('false'));
      });

      test('parses integer values', () {
        final result = parser.parseGoogleServiceInfoPlist('''<plist version="1.0">
<dict>
    <key>SOME_INT</key>
    <integer>42</integer>
</dict>
</plist>''');
        expect(result, isNotNull);
        expect(result!['SOME_INT'], equals('42'));
      });

      test('parses real (float) values', () {
        final result = parser.parseGoogleServiceInfoPlist('''<plist version="1.0">
<dict>
    <key>SOME_REAL</key>
    <real>3.14</real>
</dict>
</plist>''');
        expect(result, isNotNull);
        expect(result!['SOME_REAL'], equals('3.14'));
      });

      test('parses nested dicts', () {
        final result = parser.parseGoogleServiceInfoPlist('''<plist version="1.0">
<dict>
    <key>OUTER</key>
    <dict>
        <key>INNER</key>
        <string>value</string>
    </dict>
    <key>AFTER</key>
    <string>after</string>
</dict>
</plist>''');
        expect(result, isNotNull);
        expect(result!['AFTER'], equals('after'));
      });

      test('handles array values by converting to string', () {
        final result = parser.parseGoogleServiceInfoPlist('''<plist version="1.0">
<dict>
    <key>ITEMS</key>
    <array>
        <string>item1</string>
        <string>item2</string>
    </array>
    <key>NAME</key>
    <string>test</string>
</dict>
</plist>''');
        expect(result, isNotNull);
        expect(result!['NAME'], equals('test'));
      });

      test('handles complex plist with all types', () {
        final result = parser.parseGoogleServiceInfoPlist('''<plist version="1.0">
<dict>
    <key>STRING_KEY</key>
    <string>hello</string>
    <key>BOOL_TRUE</key>
    <true/>
    <key>BOOL_FALSE</key>
    <false/>
    <key>INT_KEY</key>
    <integer>100</integer>
    <key>REAL_KEY</key>
    <real>2.718</real>
    <key>NESTED</key>
    <dict>
        <key>INNER_STR</key>
        <string>inner</string>
    </dict>
    <key>LIST</key>
    <array>
        <string>a</string>
        <string>b</string>
    </array>
</dict>
</plist>''');
        expect(result, isNotNull);
        expect(result!['STRING_KEY'], equals('hello'));
        expect(result['BOOL_TRUE'], equals('true'));
        expect(result['BOOL_FALSE'], equals('false'));
        expect(result['INT_KEY'], equals('100'));
        expect(result['REAL_KEY'], equals('2.718'));
        expect(result['NESTED'], isNotNull);
        expect(result.keys.length, greaterThanOrEqualTo(7));
      });
    });

    group('parseInfoPlist', () {
      test('parses background modes from Info.plist', () {
        final result = parser.parseInfoPlist('''<plist version="1.0">
<dict>
    <key>UIBackgroundModes</key>
    <array>
        <string>remote-notification</string>
        <string>fetch</string>
    </array>
</dict>
</plist>''');
        expect(result.backgroundModes, contains('remote-notification'));
        expect(result.backgroundModes, contains('fetch'));
        expect(result.hasFirebaseAppDelegateProxy, isFalse);
      });

      test('returns empty list when no background modes', () {
        final result = parser.parseInfoPlist('<plist><dict></dict></plist>');
        expect(result.backgroundModes, isEmpty);
        expect(result.hasFirebaseAppDelegateProxy, isFalse);
      });

      test('detects FirebaseAppDelegateProxyEnabled', () {
        final result = parser.parseInfoPlist('''<plist version="1.0">
<dict>
    <key>FirebaseAppDelegateProxyEnabled</key>
    <false/>
</dict>
</plist>''');
        expect(result.hasFirebaseAppDelegateProxy, isTrue);
        expect(result.backgroundModes, isEmpty);
      });

      test('parses both background modes and proxy setting', () {
        final result = parser.parseInfoPlist('''<plist version="1.0">
<dict>
    <key>UIBackgroundModes</key>
    <array>
        <string>remote-notification</string>
    </array>
    <key>FirebaseAppDelegateProxyEnabled</key>
    <false/>
</dict>
</plist>''');
        expect(result.backgroundModes, contains('remote-notification'));
        expect(result.hasFirebaseAppDelegateProxy, isTrue);
      });

      test('handles empty Info.plist gracefully', () {
        final result = parser.parseInfoPlist('not a plist');
        expect(result.backgroundModes, isEmpty);
        expect(result.hasFirebaseAppDelegateProxy, isFalse);
      });

      test('handles malformed plist gracefully', () {
        final result = parser.parseInfoPlist('<plist><dict><key>UIBackgroundModes</key></dict></plist>');
        expect(result.backgroundModes, isEmpty);
        expect(result.hasFirebaseAppDelegateProxy, isFalse);
      });
    });

    group('parseFirebaseAppDelegateProxyValue', () {
      test('returns null when key is absent', () {
        final result = parser.parseFirebaseAppDelegateProxyValue(
          '<plist><dict><key>SomeKey</key><string>val</string></dict></plist>',
        );
        expect(result, isNull);
      });

      test('returns true when set to <true/>', () {
        final result = parser.parseFirebaseAppDelegateProxyValue(
          '<plist><dict><key>FirebaseAppDelegateProxyEnabled</key><true/></dict></plist>',
        );
        expect(result, isTrue);
      });

      test('returns false when set to <false/>', () {
        final result = parser.parseFirebaseAppDelegateProxyValue(
          '<plist><dict><key>FirebaseAppDelegateProxyEnabled</key><false/></dict></plist>',
        );
        expect(result, isFalse);
      });

      test('returns null for empty content', () {
        final result = parser.parseFirebaseAppDelegateProxyValue('');
        expect(result, isNull);
      });

      test('returns null for non-plist content', () {
        final result = parser.parseFirebaseAppDelegateProxyValue('not a plist');
        expect(result, isNull);
      });
    });

    group('edge cases in _parseDict and _parseArray', () {
      test('handles plist with content after closing dict', () {
        final result = parser.parseGoogleServiceInfoPlist('''<plist version="1.0">
<dict>
    <key>KEY</key>
    <string>value</string>
</dict>
trailing content after closing
</plist>''');
        expect(result, isNotNull);
        expect(result!['KEY'], equals('value'));
      });

      test('handles unexpected text between key-value pairs', () {
        final result = parser.parseGoogleServiceInfoPlist('''<plist version="1.0">
<dict>
    <key>FIRST</key>
    <string>first</string>
    unexpected interstitial text
    <key>SECOND</key>
    <string>second</string>
</dict>
</plist>''');
        expect(result, isNotNull);
        expect(result!['FIRST'], equals('first'));
        expect(result!['SECOND'], equals('second'));
      });

      test('handles array with text content between items', () {
        final result = parser.parseGoogleServiceInfoPlist('''<plist version="1.0">
<dict>
    <key>ITEMS</key>
    <array>
        random text
        <string>item1</string>
        <string>item2</string>
    </array>
</dict>
</plist>''');
        expect(result, isNotNull);
      });

      test('handles deeply nested dicts', () {
        final result = parser.parseGoogleServiceInfoPlist('''<plist version="1.0">
<dict>
    <key>LEVEL1</key>
    <dict>
        <key>LEVEL2</key>
        <dict>
            <key>LEVEL3</key>
            <string>deep</string>
        </dict>
    </dict>
</dict>
</plist>''');
        expect(result, isNotNull);
        expect(result!['LEVEL1'], isNotNull);
      });
    });
  });
}
