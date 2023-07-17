import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:math';

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
        primarySwatch: Colors.green,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      initialRoute: '/',
      onGenerateRoute: (RouteSettings settings) {
        switch (settings.name) {
          case '/':
            return PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) => Home(),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return FadeTransition(
                  opacity: animation,
                  child: child,
                );
              },
            );
          case '/loginwp':
            return PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) => LoginWPPage(),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(1.0, 0.0),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                );
              },
            );
          case '/register':
            return PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) => RegisterPage(),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return ScaleTransition(
                  scale: animation,
                  child: child,
                );
              },
            );
          case '/display':
            return PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) => DisplayPage(user: user),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return FadeTransition(
                  opacity: animation,
                  child: child,
                );
              },
            );
          case '/viewTasks':
            return PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) => TaskListPage(),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return ScaleTransition(
                  scale: animation,
                  child: child,
                );
              },
            );
          default:
            return null;
        }
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
  String randomText = '';

  final List<String> texts = [
    '"I hated every minute of training, however if you suffer now, you can live the rest of your life as a champion." -Muhammad Ali',
    '"If you do not find the time, if you do not do the work, you do not get the results." - Arnold Schwarzenegger',
    '"I have failed over and over again in my life and that is why I succeed." - Michael Jordan',
    '"If something stands between you and your success, move it. Never be denied." -Dwayne "The Rock" Johnson',
    '"Great things come from hard work and perseverance. No excuses." -Kobe Bryant',
    '"If you do not make time for exercise, you will probably have to make time for illness" -Robin Sharma',
    '"We are what we repeatedly do. Excellence then is not an act but a habit" -Aristotle',
    '"To keep the body in good health is duty... otherwise we shall not be able to keep our mind strong and clear" -Buddha',
    '"Some people want it to happen, some wish it would happen, others make it happen" -Michael Jordan',
    '"If you want something you never had, you must be willing to do something you have never done" -Thomas Jefferson',
  ];

  @override
  void initState() {
    super.initState();
    fetchWeather();
    generateRandomText();
  }

  @override
  void didUpdateWidget(DisplayPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    generateRandomText();
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
          final temperature = weatherData['current']['temp_f'];
          setState(() {
            weatherInfo =
            'Current Weather: $currentCondition, Temperature: $temperature°F';
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

  void generateRandomText() {
    final random = Random();
    final index = random.nextInt(texts.length);
    setState(() {
      randomText = texts[index];
    });
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
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Text(
                  'Welcome!',
                  style: TextStyle(fontSize: 24),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 20),
                Text(
                  'Logged in as:',
                  style: TextStyle(fontSize: 18),
                ),
                Text(
                  widget.user?.email ?? '',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Image.asset(
              'images/jump.gif',
              width: 200,
              height: 200,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              randomText,
              style: TextStyle(fontSize: 18),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
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
  final TextEditingController _titleControllerAdd = TextEditingController();
  final TextEditingController _descriptionControllerAdd = TextEditingController();
  final TextEditingController _countControllerAdd = TextEditingController();
  final TextEditingController _dueDateControllerAdd = TextEditingController();
  final TextEditingController _titleControllerEdit = TextEditingController();
  final TextEditingController _descriptionControllerEdit = TextEditingController();
  final TextEditingController _countControllerEdit = TextEditingController();
  final TextEditingController _dueDateControllerEdit = TextEditingController();

  Future<void> _createTask(tTitle, tDescription, tCount, tDate) async {
    final title = tTitle;
    final description = tDescription;

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
        'count': tCount,
        'dueDate': tDate,
        'status': 'pending',
      });
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
        backgroundColor: Colors.green,
      ),
      body: Column(
        children: [
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
                      final count = task?['count'] as String?;
                      final date = task?['dueDate'] as String?;
                      final status = task?['status'] as String?;
                      var countString = "";
                      if(count != null){
                        countString = "- Count: $count";
                      }
                      return ListTile(
                        title: Text("${title ?? ''}"),
                        subtitle: Text("${(description ?? '')} $countString\nDue $date"),
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
                        onLongPress: (){
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              //var titleString = title;
                              return AlertDialog(
                                scrollable: true,
                                title: const Text("Edit Exercise"),
                                content: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: SingleChildScrollView(
                                    child: Column(
                                      children: [
                                        TextFormField(
                                          controller: _titleControllerEdit,
                                          decoration: InputDecoration(
                                            labelText: "Title: $title",
                                          ),
                                        ),
                                        TextFormField(
                                          controller: _descriptionControllerEdit,
                                          decoration: InputDecoration(
                                            labelText: "Description: $description",
                                          ),
                                        ),
                                        TextFormField(
                                          controller: _countControllerEdit,
                                          decoration: InputDecoration(
                                            labelText: "Count: $count",
                                          ),
                                        ),
                                        TextFormField(
                                            controller: _dueDateControllerEdit,
                                            decoration: InputDecoration(
                                              labelText: "Due Date: $date",
                                            ),
                                            readOnly: true,
                                            onTap: () async {
                                              DateTime? pickedDate = await showDatePicker(
                                                  context: context,
                                                  initialDate: DateTime.now(), //get today's date
                                                  firstDate: DateTime.now(), //DateTime.now() - not to allow to choose before today.
                                                  lastDate: DateTime(2100)
                                              );
                                              if(pickedDate != null){
                                                String formattedDate = DateFormat('yyyy-MM-dd').format(pickedDate);
                                                setState(() {
                                                  _dueDateControllerEdit.text = formattedDate;
                                                });
                                              }
                                            }
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                actions: [
                                  ElevatedButton(
                                    child: const Text("submit"),
                                    onPressed: () {
                                      var title = _titleControllerEdit.text;
                                      var desc = _descriptionControllerEdit.text;
                                      var count = int.tryParse(_countControllerEdit.text);
                                      var date = _dueDateControllerEdit.text;
                                      if(title==""){
                                        showDialog(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title: Text('You must enter a title.'),
                                            actions: [
                                              TextButton(
                                                child: Text('OK'),
                                                onPressed: () => Navigator.pop(context),
                                              ),
                                            ],
                                          ),
                                        );
                                      } else if(date == null){
                                        showDialog(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title: Text('You must enter a due date.'),
                                            actions: [
                                              TextButton(
                                                child: Text('OK'),
                                                onPressed: () => Navigator.pop(context),
                                              ),
                                            ],
                                          ),
                                        );
                                      }
                                      else{
                                        _deleteTask(tasks[index].id);
                                        _createTask(title, desc, count, date);
                                        _titleControllerEdit.clear();
                                        _descriptionControllerEdit.clear();
                                        _countControllerEdit.clear();
                                        _dueDateControllerEdit.clear();
                                        Navigator.pop(context);
                                      }
                                    },
                                  ),
                                ],
                              );
                            },
                          );
                        },
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
      floatingActionButton: FloatingActionButton(
          onPressed: (){
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  scrollable: true,
                  title: const Text("Add Exercise"),
                  content: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _titleControllerAdd,
                            decoration: const InputDecoration(
                              labelText: "Exercise Name",
                            ),
                          ),
                          TextFormField(
                            controller: _descriptionControllerAdd,
                            decoration: const InputDecoration(
                              labelText: "Description",
                            ),
                          ),
                          TextFormField(
                            controller: _countControllerAdd,
                            decoration: InputDecoration(
                              labelText: "Count",
                            ),
                          ),
                          TextFormField(
                              controller: _dueDateControllerAdd,
                              decoration: InputDecoration(
                                labelText: "Due Date",
                              ),
                              readOnly: true,
                              onTap: () async {
                                DateTime? pickedDate = await showDatePicker(
                                    context: context,
                                    initialDate: DateTime.now(), //get today's date
                                    firstDate: DateTime.now(), //DateTime.now() - not to allow to choose before today.
                                    lastDate: DateTime(2100)
                                );
                                if(pickedDate != null){
                                  String formattedDate = DateFormat('yyyy-MM-dd').format(pickedDate);
                                  setState(() {
                                    _dueDateControllerAdd.text = formattedDate;
                                  });
                                }
                              }
                          ),
                        ],
                      ),
                    ),
                  ),
                  actions: [
                    ElevatedButton(
                      child: const Text("submit"),
                      onPressed: () {
                        var title = _titleControllerAdd.text;
                        var desc = _descriptionControllerAdd.text;
                        var count = _countControllerAdd.text;
                        var date = _dueDateControllerAdd.text;
                        if(title==""){
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text('You must enter a title.'),
                              actions: [
                                TextButton(
                                  child: Text('OK'),
                                  onPressed: () => Navigator.pop(context),
                                ),
                              ],
                            ),
                          );
                        } else if(date == null){
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text('You must enter a due date.'),
                              actions: [
                                TextButton(
                                  child: Text('OK'),
                                  onPressed: () => Navigator.pop(context),
                                ),
                              ],
                            ),
                          );
                        }
                        else{
                          _createTask(title, desc, count, date);
                          _titleControllerAdd.clear();
                          _descriptionControllerAdd.clear();
                          _countControllerAdd.clear();
                          _dueDateControllerAdd.clear();
                          Navigator.pop(context);
                        }
                      },
                    ),
                  ],
                );
              },
            );
          },
          backgroundColor: Colors.green,
          child: const Icon(Icons.add)
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
        backgroundColor: Colors.green,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.only(top: 80), // Adjust the value as needed
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
                style: const ButtonStyle(
                  backgroundColor: MaterialStatePropertyAll<Color>(Colors.green),
                ),
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
        backgroundColor: Colors.green,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.only(top: 80), // Adjust the value as needed
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
                style: const ButtonStyle(
                  backgroundColor: MaterialStatePropertyAll<Color>(Colors.green),
                ),
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
      ),
    );
  }
}