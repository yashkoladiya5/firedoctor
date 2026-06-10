import 'package:test/test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:firedoctor/logging/logger.dart';
import 'package:firedoctor/terminal/terminal_interface.dart';

class MockTerminal extends Mock implements Terminal {}

void main() {
  late MockTerminal terminal;
  late Logger logger;

  setUp(() {
    terminal = MockTerminal();
    logger = Logger(terminal: terminal);
  });

  group('Logger', () {
    group('info', () {
      test('calls terminal.writeInfo with message', () {
        when(() => terminal.writeInfo(any())).thenReturn(null);
        logger.info('test info');
        verify(() => terminal.writeInfo('test info')).called(1);
      });

      test('includes name prefix when provided', () {
        final namedLogger = Logger(terminal: terminal, name: 'Test');
        when(() => terminal.writeInfo(any())).thenReturn(null);
        namedLogger.info('test info');
        verify(() => terminal.writeInfo('[Test] test info')).called(1);
      });
    });

    group('success', () {
      test('calls terminal.writeSuccess with message', () {
        when(() => terminal.writeSuccess(any())).thenReturn(null);
        logger.success('test success');
        verify(() => terminal.writeSuccess('test success')).called(1);
      });

      test('includes name prefix when provided', () {
        final namedLogger = Logger(terminal: terminal, name: 'Test');
        when(() => terminal.writeSuccess(any())).thenReturn(null);
        namedLogger.success('test success');
        verify(() => terminal.writeSuccess('[Test] test success')).called(1);
      });
    });

    group('warning', () {
      test('calls terminal.writeWarning with message', () {
        when(() => terminal.writeWarning(any())).thenReturn(null);
        logger.warning('test warning');
        verify(() => terminal.writeWarning('test warning')).called(1);
      });

      test('includes name prefix when provided', () {
        final namedLogger = Logger(terminal: terminal, name: 'Test');
        when(() => terminal.writeWarning(any())).thenReturn(null);
        namedLogger.warning('test warning');
        verify(() => terminal.writeWarning('[Test] test warning')).called(1);
      });
    });

    group('error', () {
      test('calls terminal.writeError with message', () {
        when(() => terminal.writeError(any())).thenReturn(null);
        logger.error('test error');
        verify(() => terminal.writeError('test error')).called(1);
      });

      test('includes name prefix when provided', () {
        final namedLogger = Logger(terminal: terminal, name: 'Test');
        when(() => terminal.writeError(any())).thenReturn(null);
        namedLogger.error('test error');
        verify(() => terminal.writeError('[Test] test error')).called(1);
      });
    });

    group('header', () {
      test('adds separator lines and title', () {
        when(() => terminal.writeLine(any())).thenReturn(null);
        logger.header('Test Header');
        verify(() => terminal.writeLine('')).called(2);
        verify(() => terminal.writeLine('=== Test Header ===')).called(1);
      });
    });

    group('blank', () {
      test('adds empty line', () {
        when(() => terminal.writeLine(any())).thenReturn(null);
        logger.blank();
        verify(() => terminal.writeLine('')).called(1);
      });
    });
  });
}
