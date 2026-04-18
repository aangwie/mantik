import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/login_profile_model.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('login_profiles.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    const defaultType = 'TEXT NOT NULL';
    const integerType = 'INTEGER NOT NULL';
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';

    await db.execute('''
CREATE TABLE login_profiles (
  id $idType,
  profileName $defaultType,
  host $defaultType,
  port $integerType,
  username $defaultType,
  password $defaultType
)
''');
  }

  Future<LoginProfile> create(LoginProfile profile) async {
    final db = await instance.database;
    final id = await db.insert('login_profiles', profile.toMap());
    return profile.copyWith(id: id);
  }

  Future<LoginProfile?> readProfile(int id) async {
    final db = await instance.database;
    final maps = await db.query(
      'login_profiles',
      columns: ['id', 'profileName', 'host', 'port', 'username', 'password'],
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return LoginProfile.fromMap(maps.first);
    } else {
      return null;
    }
  }

  Future<List<LoginProfile>> readAllProfiles() async {
    final db = await instance.database;
    final orderBy = 'id ASC';
    final result = await db.query('login_profiles', orderBy: orderBy);
    return result.map((json) => LoginProfile.fromMap(json)).toList();
  }

  Future<int> update(LoginProfile profile) async {
    final db = await instance.database;
    return await db.update(
      'login_profiles',
      profile.toMap(),
      where: 'id = ?',
      whereArgs: [profile.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await instance.database;
    return await db.delete(
      'login_profiles',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
