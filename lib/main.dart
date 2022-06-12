import 'package:flutter/material.dart';
import 'package:untitled2/pages/home.dart';
import 'package:untitled2/pages/HomeHome.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MaterialApp(
    theme: ThemeData( //тема
      primaryColor: Colors.lightBlue, //основная тема голубая
    ),
    initialRoute: '/', //вызов класса для основной страницы (Только не класса, а открытие экрана по определенному пути)
    routes: {
      '/': (context) => HomeHome(), // Лучше дать имя HomePage или HomeScreen
      '/todo': (context) => Home(), // Лучше давать содержательные имена классам, здесь бы хорошо подошло ToDoPage или ToDoScreen
    },
  ));
}
