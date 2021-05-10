import 'package:sqflite/sqflite.dart';
import 'dart:async';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:note_keeper/models/note.dart';

class DatabaseHelper{

  static DatabaseHelper _databaseHelper;  //Singleton DatabaseHelper
  static Database _database;

  String noteTable = 'noteTable';
  String colId = 'id';
  String colTitle = 'title';
  String colDescription = 'description';
  String colPriority = 'priority';
  String colDate = 'date';

  DatabaseHelper._createInstance(); //Name constructor to create instance of DatabaseHelper

  factory DatabaseHelper(){

    if(_databaseHelper == null){
      _databaseHelper = DatabaseHelper._createInstance();
    }

    return _databaseHelper;
  }

  Future<Database> get database async {
    if (_database == null) {
      _database = await initializeDatabase();
    }
    return _database;
  }

  Future<Database> initializeDatabase() async{
    //Get the directory path for both Andriod and IOS to store database
    Directory directory = await getApplicationDocumentsDirectory();
    String path = directory.path + 'notes.db';

    //Open/Create the database at a given path
    var notesDatabase = await openDatabase(path, version: 1, onCreate: _createDb);

    return notesDatabase;
  }

  void _createDb(Database db, int newVersion) async{

    await db.execute('CREATE TABLE $noteTable ($colId INTEGER PRIMARY KEY AUTOINCREMENT,'
        '$colTitle TEXT, $colDescription TEXT, $colPriority INTEGER, $colDate TEXT)');
  }

  //Fetch Operation: Get all note objects from database
  Future<List<Map<String, dynamic>>> getNoteMapList() async{
    Database db = await this.database;

    //both get the same result, 1. raw query 2. helper
    //var result = await db.rawQuery('SELECT * FROM $noteTable order by $colPriority ASC');
    var result = await db.query(noteTable, orderBy: '$colPriority ASC');

    return result;
  }

  //Insert Operation: Insert a Note object to database
  Future<int> insertNote(Note note) async{
    Database db = await this.database;
    var result = await db.insert(noteTable, note.toMap());
    return result;
  }

  //Update Operation: Update a Note object and save it to database
  Future<int> updateNote(Note note) async{
    var db = await this.database;
    var result = await db.update(noteTable, note.toMap(), where: '$colId = ?', whereArgs: [note.id]);
    return result;
  }

  //Delete Operation: Delete a Note object from database
  Future<int> deleteNote(int id) async{
    var db = await this.database;
    var result = await db.rawDelete('DELETE FROM $noteTable WHERE $colId = $id');
    return result;
  }

  //Get number of Note objects in database
  Future<int> getCount() async{
    Database db = await this.database;
    List<Map<String, dynamic>> x = await db.rawQuery('SELECT COUNT (*) FROM $noteTable');
    int result = Sqflite.firstIntValue(x);
    return result;
  }

  //Get the 'Map List' [List<Map>] and convert to 'Note List' [List<Note>]
  Future<List<Note>> getNoteList() async {
    var noteMapList = await getNoteMapList(); //Get 'Map List' from database
    int count = noteMapList.length;           //Count the number of map entries in db table

    List<Note> noteList = List<Note>();
    //For loop to create 'Note List' from a 'Map List'
    for(int i=0; i<count; i++){
      noteList.add(Note.fromMapObject(noteMapList[i]));
    }

    return noteList;
  }
}