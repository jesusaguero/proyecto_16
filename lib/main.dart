import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CRUD Cursos',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.grey[200],
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: CoursesScreen(),
    );
  }
}

class Course {
  int? id;
  String nombreCurso;
  String docente;
  int creditos;
  String duracion;

  Course({
    this.id,
    required this.nombreCurso,
    required this.docente,
    required this.creditos,
    required this.duracion,
  });

  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      id: json['id'],
      nombreCurso: json['nombre_curso'],
      docente: json['docente'],
      creditos: json['creditos'],
      duracion: json['duracion'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nombre_curso': nombreCurso,
      'docente': docente,
      'creditos': creditos,
      'duracion': duracion,
    };
  }
}

class ApiService {
  final String baseUrl = 'http://localhost:3000/api';

  Future<List<Course>> fetchCourses() async {
    final response = await http.get(Uri.parse('$baseUrl/cursos'));

    if (response.statusCode == 200) {
      List jsonResponse = json.decode(response.body);
      return jsonResponse.map((course) => Course.fromJson(course)).toList();
    } else {
      throw Exception('Failed to load courses');
    }
  }

  Future<Course> createCourse(Course course) async {
    final response = await http.post(
      Uri.parse('$baseUrl/cursos'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(course.toJson()),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      return Course.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to create course');
    }
  }

  Future<void> updateCourse(int id, Course course) async {
    final response = await http.put(
      Uri.parse('$baseUrl/cursos/$id'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(course.toJson()),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update course');
    }
  }

  Future<void> deleteCourse(int id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/cursos/$id'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete course');
    }
  }
}

class CoursesScreen extends StatefulWidget {
  @override
  _CoursesScreenState createState() => _CoursesScreenState();
}

class _CoursesScreenState extends State<CoursesScreen> {
  final ApiService apiService = ApiService();
  late Future<List<Course>> futureCourses;

  @override
  void initState() {
    super.initState();
    futureCourses = apiService.fetchCourses();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('CRUD Cursos'),
      ),
      body: FutureBuilder<List<Course>>(
        future: futureCourses,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else {
            final courses = snapshot.data!;
            return Column(
              children: <Widget>[
                Expanded(
                  child: ListView.builder(
                    itemCount: courses.length,
                    itemBuilder: (context, index) {
                      final course = courses[index];
                      return Card(
                        elevation: 4,
                        margin: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          title: Text(
                            course.nombreCurso,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(height: 5),
                              Text('Docente: ${course.docente}'),
                              SizedBox(height: 5),
                              Text('Créditos: ${course.creditos.toString()}'),
                              SizedBox(height: 5),
                              Text('Duración: ${course.duracion}'),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(Icons.edit),
                                onPressed: () => _displayCourseDialog(context, course),
                              ),
                              IconButton(
                                icon: Icon(Icons.delete),
                                onPressed: () => _deleteCourse(context, course.id!),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  margin: EdgeInsets.symmetric(horizontal: 20),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    onPressed: () => _displayCourseDialog(context, null),
                    child: Text(
                      'Agregar Nuevo Curso',
                      style: TextStyle(
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 16),
              ],
            );
          }
        },
      ),
    );
  }

  Future<void> _displayCourseDialog(BuildContext context, Course? course) async {
    final _formKey = GlobalKey<FormState>();
    String? nombreCurso = course?.nombreCurso;
    String? docente = course?.docente;
    int? creditos = course?.creditos;
    String? duracion = course?.duracion;

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(course == null ? 'Agregar Curso' : 'Editar Curso'),
          content: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                TextFormField(
                  initialValue: nombreCurso,
                  decoration: InputDecoration(
                    labelText: 'Nombre del Curso',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingrese el nombre del curso';
                    }
                    nombreCurso = value;
                    return null;
                  },
                ),
                SizedBox(height: 10),
                TextFormField(
                  initialValue: docente,
                  decoration: InputDecoration(
                    labelText: 'Docente',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingrese el docente';
                    }
                    docente = value;
                    return null;
                  },
                ),
                SizedBox(height: 10),
                TextFormField(
                  initialValue: creditos?.toString(),
                  decoration: InputDecoration(
                    labelText: 'Créditos',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingrese los créditos';
                    }
                    creditos = int.tryParse(value);
                    if (creditos == null) {
                      return 'Por favor ingrese un número válido';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 10),
                TextFormField(
                  initialValue: duracion,
                  decoration: InputDecoration(
                    labelText: 'Duración',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingrese la duración';
                    }
                    duracion = value;
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
              ),
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  if (course == null) {
                    apiService.createCourse(Course(
                      nombreCurso: nombreCurso!,
                      docente: docente!,
                      creditos: creditos!,
                      duracion: duracion!,
                    )).then((value) {
                      setState(() {
                        futureCourses = apiService.fetchCourses();
                      });
                    });
                  } else {
                    apiService.updateCourse(course.id!, Course(
                      id: course.id,
                      nombreCurso: nombreCurso!,
                      docente: docente!,
                      creditos: creditos!,
                      duracion: duracion!,
                    )).then((value) {
                      setState(() {
                        futureCourses = apiService.fetchCourses();
                      });
                    });
                  }
                  Navigator.of(context).pop();
                }
              },
              child: Text('Guardar'),
            ),
          ],
        );
      },
    );
  }

  void _deleteCourse(BuildContext context, int id) {
    apiService.deleteCourse(id).then((value) {
      setState(() {
        futureCourses = apiService.fetchCourses();
      });
    });
  }
}
