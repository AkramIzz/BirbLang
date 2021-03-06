import 'dart:convert';
import 'dart:io';

import 'package:Birb/utils/AST.dart';
import 'package:Birb/utils/exceptions.dart';
import 'package:Birb/utils/lexer.dart';
import 'package:Birb/utils/parser.dart';
import 'package:Birb/utils/runtime.dart';

Future<void> main(List<String> arguments) async {
  /// If no file path is specified the birb shell will
  /// start up allowing developers to write programs directly from their terminal
  bool isInteractive = false;

  /// Runtime visitor
  Runtime runtime = initRuntime();

  Lexer lexer;

  Parser parser;

  /// Parsed program
  AST node;

  // No file path is specified, Initiate the birb shell
  if (arguments.isEmpty) {
    isInteractive = true;

    print('<<<<< Birb Shell Initiated >>>>>');

    while (isInteractive) {
      stdout.write('> ');
      String str = stdin.readLineSync(encoding: Encoding.getByName('utf-8'));

      if (RegExp('{').allMatches(str).length >
          RegExp('}').allMatches(str).length) {
        while (RegExp('{').allMatches(str).length >
            RegExp('}').allMatches(str).length) {
          stdout.write('>> ');
          str += stdin.readLineSync(encoding: Encoding.getByName('utf-8'));
        }
      }

      if (RegExp('{').allMatches(str).length <
          RegExp('}').allMatches(str).length) {
        throw UnexpectedTokenException('Unexpected token `}`');
      }

      // Exit shell
      if (str == 'quit()') {
        isInteractive = false;
        break;
      }

      // Initialize and run program
      lexer = initLexer(str);
      parser = initParser(lexer);
      node = parse(parser);
      await visit(runtime, node);
    }

    print('<<<<< Birb Shell Terminated >>>>>');
    return;
  }

  // Initialize and run program
  String program = File(arguments[0]).readAsStringSync();

  if (RegExp('{').allMatches(program).length !=
      RegExp('}').allMatches(program).length) {
    int lParenCount = RegExp('{').allMatches(program).length;
    Iterable<RegExpMatch> rParenMatches = RegExp('}').allMatches(program);
    int rParenCount = rParenMatches.length;

    if (lParenCount > rParenCount) {
      throw UnexpectedTokenException(
          '[Line ${program.split('\n').length}] Expected `}`, but got EOF');
    } else if (lParenCount < rParenCount) {
      int parenCount = 0;
      rParenMatches.forEach((e) {
        parenCount += 1;
        if (parenCount > lParenCount) {
          throw UnexpectedTokenException(
              '[Line ${program.substring(0, e.start).split('\n').length}]');
        }
      });
    }
  }

  lexer = initLexer(program);
  parser = initParser(lexer);
  node = parse(parser);
  await visit(runtime, node);
}
