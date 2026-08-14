import 'package:sqflite/sqflite.dart';

DatabaseFactory getWebDatabaseFactory() {
  throw UnsupportedError('Web DatabaseFactory is not supported on IO platforms');
}
