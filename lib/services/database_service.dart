import 'package:path/path.dart';
import '../models/goal.dart';
import '../models/task.dart';
import '../models/action_log.dart';
import '../models/ai_decision.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseService {
  static Database? _database;
  
  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'dailymate.db');
    return await openDatabase(
      path,
      version: 2,  // 버전 1 → 2로 업그레이드
      onCreate: _createTables,
      onUpgrade: _onUpgrade,
    );
  }

  static Future<void> _createTables(Database db, int version) async {
    await db.execute('''
      CREATE TABLE goals(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        status TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE tasks(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        goal_id INTEGER,
        title TEXT NOT NULL,
        estimated_minutes INTEGER NOT NULL,
        status TEXT NOT NULL,
        created_at INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE action_logs(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        task_id INTEGER NOT NULL,
        action_type TEXT NOT NULL,
        timestamp INTEGER NOT NULL,
        actual_minutes INTEGER,
        FOREIGN KEY (task_id) REFERENCES tasks (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE ai_decisions(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        trigger_event TEXT NOT NULL,
        llm_input_summary TEXT NOT NULL,
        llm_output_json TEXT NOT NULL,
        bias_detected TEXT,
        created_at INTEGER NOT NULL
      )
    ''');
  }

  // DB 마이그레이션 (버전 1 → 2)
  static Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // tasks 테이블을 재생성 (goal_id를 nullable로 변경)
      await db.execute('DROP TABLE IF EXISTS action_logs');
      await db.execute('DROP TABLE IF EXISTS tasks');
      
      await db.execute('''
        CREATE TABLE tasks(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          goal_id INTEGER,
          title TEXT NOT NULL,
          estimated_minutes INTEGER NOT NULL,
          status TEXT NOT NULL,
          created_at INTEGER NOT NULL
        )
      ''');

      await db.execute('''
        CREATE TABLE action_logs(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          task_id INTEGER NOT NULL,
          action_type TEXT NOT NULL,
          timestamp INTEGER NOT NULL,
          actual_minutes INTEGER,
          FOREIGN KEY (task_id) REFERENCES tasks (id)
        )
      ''');
    }
  }


  // Goals CRUD
  static Future<int> insertGoal(Goal goal) async {
    final db = await database;
    return await db.insert('goals', goal.toMap());
  }

  static Future<List<Goal>> getActiveGoals() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'goals',
      where: 'status = ?',
      whereArgs: ['active'],
    );
    return List.generate(maps.length, (i) => Goal.fromMap(maps[i]));
  }

  // Tasks CRUD
  static Future<int> insertTask(Task task) async {
    final db = await database;
    return await db.insert('tasks', task.toMap());
  }

  static Future<List<Task>> getTodayTasks() async {
    final db = await database;
    // tasks와 goals를 조인하여 목표 제목을 함께 가져옴
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT t.*, g.title as goal_title 
      FROM tasks t 
      LEFT JOIN goals g ON t.goal_id = g.id
      ORDER BY t.created_at DESC
    ''');
    return List.generate(maps.length, (i) => Task.fromMap(maps[i]));
  }

  static Future<void> updateTaskStatus(int taskId, String status) async {
    final db = await database;
    await db.update(
      'tasks',
      {'status': status},
      where: 'id = ?',
      whereArgs: [taskId],
    );
  }

  static Future<void> updateTaskTitle(int taskId, String title) async {
    final db = await database;
    await db.update(
      'tasks',
      {'title': title},
      where: 'id = ?',
      whereArgs: [taskId],
    );
  }

  static Future<void> deleteTask(int taskId) async {
    final db = await database;
    await db.delete(
      'tasks',
      where: 'id = ?',
      whereArgs: [taskId],
    );
  }

  static Future<void> updateGoalTitle(int goalId, String title) async {
    final db = await database;
    await db.update(
      'goals',
      {'title': title},
      where: 'id = ?',
      whereArgs: [goalId],
    );
  }

  static Future<void> deleteGoal(int goalId) async {
    final db = await database;
    await db.delete(
      'goals',
      where: 'id = ?',
      whereArgs: [goalId],
    );
  }


  // Action Logs CRUD
  static Future<int> insertActionLog(ActionLog log) async {
    final db = await database;
    return await db.insert('action_logs', log.toMap());
  }

  // AI Decisions CRUD
  static Future<int> insertAiDecision(AiDecision decision) async {
    final db = await database;
    return await db.insert('ai_decisions', decision.toMap());
  }

  // Delete operations
  static Future<void> deleteAllData() async {
    final db = await database;
    await db.delete('action_logs');
    await db.delete('tasks');
    await db.delete('goals');
    await db.delete('ai_decisions');
  }

  static Future<void> deleteDatabaseFile() async {
    String path = join(await getDatabasesPath(), 'dailymate.db');
    await databaseFactory.deleteDatabase(path);
    _database = null;
  }
}