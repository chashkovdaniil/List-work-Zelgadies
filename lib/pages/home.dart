import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'dart:io';
import 'package:path/path.dart' as Path;
import 'package:path_provider/path_provider.dart';

main() => runApp(Home());

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {


  int? selectedId;
  final textController = TextEditingController();

  
  // Вызов метода initState здесь лишен смысла, так как тело метода пустое
  @override
  void initState() {
    super.initState();

  }
  
  // Так как используется TextEditingController лучше переопределить метод dispose
  // Внутри него вызвать textController.dispose();
  // Это нужно для того, чтобы когда мы ушли с текущей страницы контроллер не остался в памяти устройства
  // Чтобы не было захламления
  //
  // Вот так:
  // @override
  // dispose() {
  //    textController.dispose();
  //    super.dispose();
  // }
  
  // Методы, которые не относятся к жизненному циклу виджета лучше писать после метода build
  void _menuOpen(){
    Navigator.of(context).push(
      MaterialPageRoute(builder: (BuildContext context) {
        // Этот Scaffold можно выделить в отдельный виджет, это позволит минимизировать код в этом файле и улучшить читабельность
        return Scaffold(
          appBar: AppBar(title: Text('Меню')),
          body: Row (
            children: [
              ElevatedButton(
                  onPressed:  (){
                    Navigator.pop(context); // Это можно не вызывать, так как ниже код, который и так закрывает все страницы и открывает новую
                    Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
              },
                  child: Text('На главную страницу')
              ),
        Padding(padding: EdgeInsets.only(left: 15)),
        Text ('Просто меню')
            ],
          )
        );
      }
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold( //создаем шапку приложения
      backgroundColor: Colors.green, //фон основного окна
      appBar: AppBar(
        title: Text('Список дел'),
        centerTitle: true, // центрация названия
        actions: [ // класс в который можно передать виджеты
          IconButton(
              onPressed: _menuOpen,
              icon: Icon(Icons.menu_outlined),
          )
        ],
      ),
      body: Center(
        child: FutureBuilder<List<Grocery>>(      //вывод всего из БД
            future: DatabaseHelper.instance.getGroceries(),
            builder: (BuildContext context,
                AsyncSnapshot<List<Grocery>> snapshot) {
              if (!snapshot.hasData) {
                return Center(child: Text('Loading...'));
              }
              // Здесь можно написать что-то вроде
              // if (snapshot.data!.isEmpty) {
              //    return Center(
              //      child: Text('пустой лист'),
              //     );
              //  }
              // return ListView(
              //    ...
              // Это сделаем код более красивым
              return snapshot.data!.isEmpty
                  ? Center(child: Text('пустой лист'))
                  :ListView(
                children: snapshot.data!.map((grocery) {
                  return Center(
                    child: Card(
                      color: selectedId == grocery.id
                          ? Colors.white70
                          : Colors.white,
                      child: ListTile(
                        title: Text(grocery.name, style: TextStyle(color: Colors.green)),
                      ),
                    ),
                  );
                }).toList(),
              );
            }),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.white,
        // Здесь можно выделить код ниже в отдельный метод, структура будет лучше смотреться
        onPressed: (){
          showDialog(context: context, builder: (BuildContext context){
            return AlertDialog( //какое конкретно окно мы хотим чтобы показывалось
              title: Text('Добавить элемент'),
              content: TextField(
                controller: textController,
              ),
              actions: [
                ElevatedButton(onPressed: () async {
                selectedId != null
                ? await DatabaseHelper.instance.update(
                     Grocery(id: selectedId, name: textController.text),
                         )
                     :await DatabaseHelper.instance.add(
                 Grocery(name: textController.text)
                        );
                     setState((){
                       Navigator.of(context).pop();
                    selectedId = null;
                        }
                          );
                   //после нажатия на добавить окно закроется
                }, child: Text('Добавить'))
              ],
            );
          }); //контекст говоритт о том что мы запускаем диалоговое окно на этой же странице
        },
        child: Icon(
          Icons.add_box,
          color:Colors.greenAccent,
        ),
      ),
    );
  }
}

// Создание отдельной модели - очень хорошо)
class Grocery {   //создание базы данных
  final int? id;
  final String name;

  Grocery({this.id, required this.name});

  factory Grocery.fromMap(Map<String, dynamic> json) => new Grocery(
    id: json['id'],
    name: json['name'],
  );

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
    };
  }
}

// Создание отдельного класса для управления базой - очень хорошо!)
class DatabaseHelper {
  DatabaseHelper._privateConstructor();

  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;

  Future<Database> get database async => _database ??= await _initDatabase();

  Future <Database> _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = Path.join(documentsDirectory.path, 'groceries,db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: onCreate,
    );
  }

  FutureOr<void> onCreate(Database db, int version) async {
    await db.execute('''
    CREATE TABLE groceries(
    id INTEGER PRIMARY KEY,
    name TEXT
    )''');
  }

  Future<List<Grocery>> getGroceries() async { //добавление продуктов
    Database db = await instance.database;
    var groceries = await db.query('groceries', orderBy: 'name');
    List<Grocery> groceryList = groceries.isNotEmpty
        ? groceries.map((c) => Grocery.fromMap(c)).toList()
        : [];
    return groceryList;
  }

  Future<int> add(Grocery grocery) async {
    Database db = await instance.database;
    return await db.insert('groceries', grocery.toMap());
  }

  Future<int> update(Grocery grocery) async { //обновление списка
    Database db = await instance.database;
    return await db.update('groceries', grocery.toMap(),
        where: "id = ?", whereArgs: [grocery.id]);
  }

  Future<int> remove(int id) async { //удаление продукта
    Database db = await instance.database;
    return await db.delete('groceries', where: 'id = ?', whereArgs: [id]);
  }
}
