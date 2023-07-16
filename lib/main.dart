import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<UserCredential?> signUpWithEmailAndPassword(
      String email, String password) async {
    try {
      final UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);
      return userCredential;
    } catch (e) {
      // Handle sign-up errors
      print(e.toString());
      return null;
    }
  }

  Future<UserCredential> signInWithEmailPassword(
      String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
          email: email, password: password);
    } catch (e) {
      throw Exception('Error signing in with email and password: $e');
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw Exception('Error signing out: $e');
    }
  }
}

class MyApp extends StatelessWidget {
  get user => null;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gym Buddy',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => Home(),
        '/loginwp': (context) => LoginWPPage(),
        '/register': (context) => RegisterPage(),
        '/display': (context) => DisplayPage(user: user),
        '/viewTasks': (context) => TaskListPage(),
      },
    );
  }
}

class Home extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Home'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'Welcome to the Gym Buddy Task Manager App',
              style: TextStyle(fontSize: 30),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              child: Text('Login'),
              onPressed: () {
                Navigator.pushNamed(context, '/loginwp');
              },
            ),
            SizedBox(height: 10),
            TextButton(
              child: Text('Create an account'),
              onPressed: () {
                Navigator.pushNamed(context, '/register');
              },
            ),
          ],
        ),
      ),
    );
  }
}

class DisplayPage extends StatefulWidget {
  final User? user;

  DisplayPage({required this.user});

  @override
  _DisplayPageState createState() => _DisplayPageState();
}

class _DisplayPageState extends State<DisplayPage> {
  String weatherInfo = '';

  @override
  void initState() {
    super.initState();
    fetchWeather();
  }

  Future<void> fetchWeather() async {
    try {
      if (await _checkLocationPermission()) {
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );

        double latitude = position.latitude;
        double longitude = position.longitude;

        final apiKey = '4cc5138cd9c1446795d143957231607';
        final url =
            'https://api.weatherapi.com/v1/current.json?key=$apiKey&q=$latitude,$longitude';
        final response = await http.get(Uri.parse(url));

        if (response.statusCode == 200) {
          final weatherData = json.decode(response.body);
          final currentCondition = weatherData['current']['condition']['text'];
          final temperature = weatherData['current']['temp_c'];
          setState(() {
            weatherInfo =
            'Current Weather: $currentCondition, Temperature: $temperature°C';
          });
        } else {
          setState(() {
            weatherInfo = 'Failed to fetch weather data';
          });
        }
      } else {
        setState(() {
          weatherInfo = 'Location permission denied';
        });
      }
    } catch (e) {
      setState(() {
        weatherInfo = 'Error fetching weather data: $e';
      });
    }
  }

  Future<bool> _checkLocationPermission() async {
    PermissionStatus status = await Permission.location.status;
    if (status.isDenied || status.isRestricted) {
      PermissionStatus permissionStatus = await Permission.location.request();
      return permissionStatus.isGranted;
    }
    return status.isGranted;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('User Page'),
        automaticallyImplyLeading: false, // Remove the back arrow
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              weatherInfo,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(
                    'Welcome!',
                    style: TextStyle(fontSize: 24),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Logged in as:',
                    style: TextStyle(fontSize: 18),
                  ),
                  SizedBox(height: 10),
                  Text(
                    widget.user?.email ?? '',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    child: Text('View Tasks'),
                    onPressed: () {
                      Navigator.pushNamed(context, '/viewTasks');
                    },
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    child: Text('Logout'),
                    onPressed: () async {
                      Navigator.pop(context, '/');
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class TaskListPage extends StatefulWidget {
  @override
  _TaskListPageState createState() => _TaskListPageState();
}

class _TaskListPageState extends State<TaskListPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  Future<void> _createTask() async {
    final title = _titleController.text;
    final description = _descriptionController.text;

    if (title.isEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Title is required'),
          actions: [
            TextButton(
              child: Text('OK'),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      );
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('tasks').add({
        'title': title,
        'description': description,
        'status': 'pending',
      });
      _titleController.clear();
      _descriptionController.clear();
    } catch (e) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Error creating task'),
          content: Text(e.toString()),
          actions: [
            TextButton(
              child: Text('OK'),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _deleteTask(String taskId) async {
    try {
      await FirebaseFirestore.instance.collection('tasks').doc(taskId).delete();
    } catch (e) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Error deleting task'),
          content: Text(e.toString()),
          actions: [
            TextButton(
              child: Text('OK'),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _updateTaskStatus(String taskId, String status) async {
    try {
      await FirebaseFirestore.instance
          .collection('tasks')
          .doc(taskId)
          .update({'status': status});
    } catch (e) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Error updating task status'),
          content: Text(e.toString()),
          actions: [
            TextButton(
              child: Text('OK'),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Task List'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      labelText: 'Title',
                    ),
                  ),
                ),
                SizedBox(width: 8.0),
                Expanded(
                  child: TextFormField(
                    controller: _descriptionController,
                    decoration: InputDecoration(
                      labelText: 'Description',
                    ),
                  ),
                ),
                SizedBox(width: 8.0),
                ElevatedButton(
                  child: Text('Add'),
                  onPressed: _createTask,
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('tasks').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  final tasks = snapshot.data!.docs;
                  return ListView.builder(
                    itemCount: tasks.length,
                    itemBuilder: (context, index) {
                      final task = tasks[index].data() as Map<String, dynamic>?;
                      final title = task?['title'] as String?;
                      final description = task?['description'] as String?;
                      final status = task?['status'] as String?;

                      return ListTile(
                        title: Text(title ?? ''),
                        subtitle: Text(description ?? ''),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            DropdownButton<String>(
                              value: status,
                              items: <String>['pending', 'complete', 'dnf']
                                  .map((String value) {
                                return DropdownMenuItem<String>(
                                  value: value.toLowerCase(),
                                  child: Text(value.toUpperCase()),
                                );
                              }).toList(),
                              onChanged: (String? newValue) {
                                if (newValue != null) {
                                  _updateTaskStatus(tasks[index].id, newValue);
                                }
                              },
                            ),
                            SizedBox(width: 8.0),
                            IconButton(
                              icon: Icon(Icons.delete),
                              onPressed: () =>
                                  _deleteTask(tasks[index].id),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                } else if (snapshot.hasError) {
                  return Center(
                    child: Text('Error retrieving tasks'),
                  );
                } else {
                  return Center(
                    child: CircularProgressIndicator(),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

class LoginWPPage extends StatefulWidget {
  @override
  _LoginWPPageState createState() => _LoginWPPageState();
}

class _LoginWPPageState extends State<LoginWPPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isEmailValid = true;
  bool isPasswordValid = true;
  bool isFormSubmitted = false;

  Future<void> _showLoginErrorDialog() {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Login Error'),
          content: Text('Incorrect email or password. Please try again.'),
          actions: <Widget>[
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Login'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'Login Page',
              style: TextStyle(fontSize: 24),
            ),
            SizedBox(height: 20),
            TextFormField(
              controller: emailController,
              onChanged: (value) {
                setState(() {
                  isEmailValid = isFormSubmitted
                      ? value.contains('@') && value.contains('.com')
                      : true;
                });
              },
              decoration: InputDecoration(
                labelText: 'Email',
                errorText: isFormSubmitted && !isEmailValid
                    ? 'Invalid email: Must include "@[mail].com"'
                    : null,
              ),
            ),
            SizedBox(height: 10),
            TextFormField(
              controller: passwordController,
              onChanged: (value) {
                setState(() {
                  isPasswordValid = isFormSubmitted ? value.length >= 6 : true;
                });
              },
              decoration: InputDecoration(
                labelText: 'Password',
                errorText: isFormSubmitted && !isPasswordValid
                    ? 'Invalid password: Must include 6 characters'
                    : null,
              ),
              obscureText: true,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              child: Text('Login'),
              onPressed: () async {
                setState(() {
                  isFormSubmitted = true;
                });

                String email = emailController.text;
                String password = passwordController.text;

                if (isEmailValid && isPasswordValid) {
                  try {
                    UserCredential userCredential =
                    await FirebaseAuth.instance.signInWithEmailAndPassword(
                      email: email,
                      password: password,
                    );
                    if (userCredential.user != null) {
                      // Successful login
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DisplayPage(user: userCredential.user),
                        ),
                      );
                    } else {
                      // Incorrect credentials
                      await _showLoginErrorDialog();
                    }
                  } catch (e) {
                    // Error occurred during login
                    await _showLoginErrorDialog();
                  }
                }
              },
            ),
            SizedBox(height: 10),
            TextButton(
              child: Text('Create an account'),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            SizedBox(height: 10),
            TextButton(
              child: Text('Go to Home Page'),
              onPressed: () {
                Navigator.pop(context, '/');
              },
            ),
          ],
        ),
      ),
    );
  }
}


class RegisterPage extends StatefulWidget {
  final AuthService _authService = AuthService();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  bool isEmailValid = true;
  bool isPasswordValid = true;
  bool isFormSubmitted = false;
  bool showSuccessMessage = false;

  @override
  Widget build(BuildContext context) {
    String email = '';
    String password = '';

    return Scaffold(
      appBar: AppBar(
        title: Text('Register'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'Register Page',
              style: TextStyle(fontSize: 24),
            ),
            SizedBox(height: 20),
            TextFormField(
              controller: widget.emailController,
              onChanged: (value) {
                setState(() {
                  email = value;
                  isEmailValid = isFormSubmitted
                      ? (value.contains('@') && value.contains('.'))
                      : true;
                });
              },
              decoration: InputDecoration(
                labelText: 'New Email',
                errorText: isFormSubmitted && !isEmailValid
                    ? 'Must include an @[mail].com'
                    : null,
              ),
            ),
            SizedBox(height: 10),
            TextFormField(
              controller: widget.passwordController,
              onChanged: (value) {
                setState(() {
                  password = value;
                  isPasswordValid =
                  isFormSubmitted ? value.length >= 6 : true;
                });
              },
              decoration: InputDecoration(
                labelText: 'New Password',
                errorText: isFormSubmitted && !isPasswordValid
                    ? 'Must include 6 characters'
                    : null,
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                setState(() {
                  isFormSubmitted = true;
                });

                if (isEmailValid && isPasswordValid) {
                  String email = widget.emailController.text;
                  String password = widget.passwordController.text;
                  UserCredential? userCredential =
                  await widget._authService.signUpWithEmailAndPassword(
                      email, password);
                  if (userCredential != null) {
                    setState(() {
                      showSuccessMessage = true;
                    });
                  } else {
                    // Sign-up failed
                  }
                }
              },
              child: Text('Register'),
            ),
            SizedBox(height: 10),
            TextButton(
              child: Text('Already have an account? Login'),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            SizedBox(height: 10),
            if (showSuccessMessage)
              ...[
                SizedBox(height: 20),
                Text(
                  'Account created!',
                  style: TextStyle(fontSize: 18, color: Colors.green),
                ),
              ],
          ],
        ),
      ),
    );
  }
}
