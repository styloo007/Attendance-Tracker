import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:table_calendar/table_calendar.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'My Attendance Tracker',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasData) {
          return HomeScreen();
        } else {
          return const LoginScreen();
        }
      },
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool isLoading = false;

  Future<void> _login() async {
    setState(() {
      isLoading = true;
    });

    try {
      if (_emailController.text.trim().isEmpty ||
          _passwordController.text.trim().isEmpty) {
        Fluttertoast.showToast(msg: 'Email and Password are Required');
        setState(() {
          isLoading = false;
        });
        return;
      }
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      Fluttertoast.showToast(msg: 'Login Successful');
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'invalid-email':
          message = 'Invalid email format';
          break;
        case 'user-not-found':
          message = 'User not found';
          break;
        case 'wrong-password':
          message = 'Incorrect password';
          break;
        default:
          message = 'Login failed';
          break;
      }
      Fluttertoast.showToast(msg: message);
    }

    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Main Title for the app,
            const Center(
              child: Text("""BunkiFy""",
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.redAccent,
                  ),
                  textAlign: TextAlign.center),
            ),

            const Center(
              child: Text(
                'Your Smart Attendance Tracker',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            const SizedBox(height: 40),

            // Sub-title for Login/Register
            const Text(
              'Login',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 20),

            // Email text field
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 10),

            // Password text field
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            const SizedBox(height: 20),

            // Loading indicator or Login button
            if (isLoading)
              Center(
                child: const CircularProgressIndicator(),
              )
            else
              Center(
                child: ElevatedButton(
                  onPressed: _login,
                  child: const Text('Login'),
                ),
              ),

            const SizedBox(height: 20),

            // Link to Registration Screen
            Center(
              child: TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const RegistrationScreen(),
                    ),
                  );
                },
                child: const Text('Don\'t have an account? Register'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  _RegistrationScreenState createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool isLoading = false;

  Future<void> _register() async {
    setState(() {
      isLoading = true;
    });

    try {
      if (_nameController.text.trim().isEmpty ||
          _emailController.text.trim().isEmpty ||
          _passwordController.text.trim().isEmpty) {
        Fluttertoast.showToast(msg: 'Name, Email, and Password are Required');
        setState(() {
          isLoading = false;
        });
        return;
      }

      await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      )
          .then((value) async {
        // Store additional user data (like name) in Firestore
        await FirebaseFirestore.instance
            .collection('users')
            .doc(value.user!.uid)
            .set({'name': _nameController.text});
      });

      Fluttertoast.showToast(msg: 'Registration Successful');
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => HomeScreen()),
        (route) =>
            false, // This ensures that all previous routes are removed from the stack
      );
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'email-already-in-use':
          message = 'This email is already registered';
          break;
        case 'invalid-email':
          message = 'Invalid email format';
          break;
        case 'weak-password':
          message = 'Password is too weak';
          break;
        default:
          message = 'Registration failed';
          break;
      }
      Fluttertoast.showToast(msg: message);
    }

    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registration')),
      body: SingleChildScrollView(
        // Wrap the Column inside a SingleChildScrollView
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Name text field
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: 10),

            // Email text field
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 10),

            // Password text field
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            const SizedBox(height: 20),

            // Loading indicator or Register button
            if (isLoading)
              Center(
                child: const CircularProgressIndicator(),
              )
            else
              Center(
                child: ElevatedButton(
                  onPressed: _register,
                  child: const Text('Register'),
                ),
              )
          ],
        ),
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Color _getAttendanceColor(String percentage) {
    // Parse the percentage (remove the '%' symbol and convert to a double)
    double percentageValue =
        double.tryParse(percentage.replaceAll('%', '')) ?? 0;

    if (percentageValue < 70) {
      return Colors.red; // Less than 70: red
    } else if (percentageValue >= 70 && percentageValue <= 85) {
      return Colors.amber; // Between 70 and 85: yellow
    } else {
      return Colors.green; // Above 85: green
    }
  }

  HomeScreen({super.key});

  String _calculatePercentage(int attended, int notAttended) {
    final total = attended + notAttended;
    if (total == 0) return '0%';
    return '${((attended / total) * 100).toStringAsFixed(1)}%';
  }

  Future<void> _logout(BuildContext context) async {
    await _auth.signOut();
    Fluttertoast.showToast(msg: 'Logout Successful');
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const AuthWrapper()),
    );
  }

  void _showCalendar(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        content: Container(
          height: 400,
          width: 300,
          child: SingleChildScrollView(
            child: TableCalendar(
              firstDay: DateTime.utc(2000, 1, 1),
              lastDay: DateTime.utc(2100, 12, 31),
              focusedDay: DateTime.now(),
              headerStyle: const HeaderStyle(
                formatButtonVisible: false,
              ),
              onFormatChanged: (format) {},
            ),
          ),
        ),
      ),
    );
  }

  // Fetch the user's name from Firestore
  Future<String> _getUserName() async {
    final userId = _auth.currentUser!.uid;
    final userDoc = await _firestore.collection('users').doc(userId).get();
    return userDoc['name'] ?? 'User'; // Default to 'User' if no name found
  }

  @override
  Widget build(BuildContext context) {
    String formattedDate =
        DateFormat('EEEE, MMMM d, yyyy').format(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blueGrey,
        title: Row(
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: ElevatedButton(
                onPressed: () => _showCalendar(context),
                child: const Text('📅'),
              ),
            ),
            Text(
              formattedDate,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: FutureBuilder<String>(
        future: _getUserName(), // Get the name
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No name found'));
          }

          final userName = snapshot.data!;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: Text(
                  'Hey, $userName!', // Display the personalized greeting
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.pink,
                    backgroundColor: Colors.transparent,
                  ),
                ),
              ),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _firestore
                      .collection('subjects')
                      .where('userId', isEqualTo: _auth.currentUser!.uid)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final subjects = snapshot.data?.docs ?? [];
                    return ListView.builder(
                      itemCount: subjects.length,
                      itemBuilder: (context, index) {
                        final subject = subjects[index];
                        final theoryPercentage = _calculatePercentage(
                          subject['attendedTheory'],
                          subject['notAttendedTheory'],
                        );
                        final practicalPercentage = _calculatePercentage(
                          subject['attendedPractical'],
                          subject['notAttendedPractical'],
                        );

                        return Card(
                          margin: const EdgeInsets.all(10),
                          elevation: 5,
                          child: ListTile(
                            title: Text(subject['name'],
                                style: const TextStyle(
                                    fontSize: 20, fontWeight: FontWeight.bold)),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Divider(),
                                Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 4.0),
                                  child: Row(
                                    children: [
                                      const Text('Theory Attendance: ',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold)),
                                      Text(theoryPercentage,
                                          style: TextStyle(
                                              color: _getAttendanceColor(
                                                  theoryPercentage))),
                                    ],
                                  ),
                                ),
                                Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 4.0),
                                  child: Row(
                                    children: [
                                      const Text('Practical Attendance: ',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold)),
                                      Text(practicalPercentage,
                                          style: TextStyle(
                                              color: _getAttendanceColor(
                                                  practicalPercentage))),
                                    ],
                                  ),
                                ),
                                const Divider(),
                                Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 4.0),
                                  child: Row(
                                    children: [
                                      const Text('Theory Attended: ',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold)),
                                      Text('${subject['attendedTheory']}'),
                                    ],
                                  ),
                                ),
                                Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 4.0),
                                  child: Row(
                                    children: [
                                      const Text('Theory Missed: ',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold)),
                                      Text('${subject['notAttendedTheory']}'),
                                    ],
                                  ),
                                ),
                                Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 4.0),
                                  child: Row(
                                    children: [
                                      const Text('Practical Attended: ',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold)),
                                      Text('${subject['attendedPractical']}'),
                                    ],
                                  ),
                                ),
                                Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 4.0),
                                  child: Row(
                                    children: [
                                      const Text('Practical Missed: ',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold)),
                                      Text(
                                          '${subject['notAttendedPractical']}'),
                                    ],
                                  ),
                                ),
                                const Divider(),
                              ],
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        SubjectManagementScreen(
                                            subjectId: subject.id),
                                  ),
                                );
                              },
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => MarkAttendanceScreen(
                                      subjectId: subject.id,
                                      subjectName: subject['name']),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => const SubjectManagementScreen()),
          );
        },
      ),
    );
  }
}

class SubjectManagementScreen extends StatefulWidget {
  final String? subjectId;

  const SubjectManagementScreen({super.key, this.subjectId});

  @override
  _SubjectManagementScreenState createState() =>
      _SubjectManagementScreenState();
}

class _SubjectManagementScreenState extends State<SubjectManagementScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _nameController = TextEditingController();
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.subjectId != null) {
      _loadSubjectData();
    }
  }

  void _loadSubjectData() async {
    final doc =
        await _firestore.collection('subjects').doc(widget.subjectId).get();
    _nameController.text = doc['name'];
  }

  void _saveSubject() async {
    setState(() {
      isLoading = true;
    });

    final data = {
      'name': _nameController.text,
      'attendedTheory': 0,
      'notAttendedTheory': 0,
      'attendedPractical': 0,
      'notAttendedPractical': 0,
      'userId': _auth.currentUser!.uid,
    };

    if (widget.subjectId == null) {
      await _firestore.collection('subjects').add(data);
      Fluttertoast.showToast(msg: 'Subject Added');
    } else {
      await _firestore
          .collection('subjects')
          .doc(widget.subjectId)
          .update({'name': _nameController.text});
      Fluttertoast.showToast(msg: 'Subject Updated');
    }

    setState(() {
      isLoading = false;
    });
    Navigator.pop(context);
  }

  void _deleteSubject() async {
    if (widget.subjectId != null) {
      await _firestore.collection('subjects').doc(widget.subjectId).delete();
      Fluttertoast.showToast(msg: 'Subject Deleted');
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title:
              Text(widget.subjectId == null ? 'Add Subject' : 'Edit Subject')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Subject Name'),
            ),
            const SizedBox(height: 20),
            if (isLoading)
              Center(
                child: const CircularProgressIndicator(),
              )
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: _saveSubject,
                    child: Text(widget.subjectId == null ? 'Add' : 'Update'),
                  ),
                  if (widget.subjectId != null)
                    ElevatedButton(
                      onPressed: _deleteSubject,
                      style:
                          ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      child: const Text('Delete'),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class MarkAttendanceScreen extends StatelessWidget {
  final String subjectId;
  final String subjectName;

  const MarkAttendanceScreen(
      {super.key, required this.subjectId, required this.subjectName});

  @override
  Widget build(BuildContext context) {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;

    // Function to decrement attendance but prevent going below 0
    Future<void> decrementAttendance(String field) async {
      final subjectDoc =
          await firestore.collection('subjects').doc(subjectId).get();
      final data = subjectDoc.data();

      // Check the current count for the field
      int currentCount = data?[field] ?? 0;

      if (currentCount > 0) {
        // Decrement only if the count is greater than 0
        firestore.collection('subjects').doc(subjectId).update({
          field: FieldValue.increment(-1),
        });
        Fluttertoast.showToast(msg: 'Undo: Attendance Marked');
      } else {
        Fluttertoast.showToast(msg: 'Cannot undo: Attendance is already 0');
      }
    }

    return Scaffold(
      appBar: AppBar(title: Text('Mark Attendance - $subjectName')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Mark Theory Attendance Button
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      fixedSize: const Size(220, 60), // Increased height
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      backgroundColor: Colors.blue, // Button background color
                      foregroundColor: Colors.white, // Button text color
                      elevation: 5, // Elevated effect
                    ),
                    onPressed: () {
                      firestore.collection('subjects').doc(subjectId).update({
                        'attendedTheory': FieldValue.increment(1),
                      });
                      Fluttertoast.showToast(msg: 'Theory Marked as Attended');
                    },
                    child: const Text(
                      'Mark Theory as Attended',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                  const SizedBox(width: 10), // Space between buttons

                  // Undo Button for Theory Attendance
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.blue.shade100),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.remove, color: Colors.blue),
                      onPressed: () {
                        decrementAttendance('attendedTheory');
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10), // Spacing between buttons

              // Mark Theory Missed Button
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      fixedSize: const Size(220, 60), // Increased height
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      backgroundColor: Colors.red, // Button background color
                      foregroundColor: Colors.white, // Button text color
                      elevation: 5, // Elevated effect
                    ),
                    onPressed: () {
                      firestore.collection('subjects').doc(subjectId).update({
                        'notAttendedTheory': FieldValue.increment(1),
                      });
                      Fluttertoast.showToast(msg: 'Theory Marked as Missed');
                    },
                    child: const Text(
                      'Mark Theory as Missed',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                  const SizedBox(width: 10), // Space between buttons

                  // Undo Button for Theory Missed
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.red.shade100),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.remove, color: Colors.red),
                      onPressed: () {
                        decrementAttendance('notAttendedTheory');
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10), // Spacing between buttons

              // Mark Practical Attendance Button
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      fixedSize: const Size(220, 60), // Increased height
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      backgroundColor: Colors.green, // Button background color
                      foregroundColor: Colors.white, // Button text color
                      elevation: 5, // Elevated effect
                    ),
                    onPressed: () {
                      firestore.collection('subjects').doc(subjectId).update({
                        'attendedPractical': FieldValue.increment(1),
                      });
                      Fluttertoast.showToast(
                          msg: 'Practical Marked as Attended');
                    },
                    child: const Text(
                      'Mark Practical as Attended',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                  const SizedBox(width: 10), // Space between buttons

                  // Undo Button for Practical Attendance
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.green.shade100),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.remove, color: Colors.green),
                      onPressed: () {
                        decrementAttendance('attendedPractical');
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10), // Spacing between buttons

              // Mark Practical Missed Button
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      fixedSize: const Size(220, 60), // Increased height
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      backgroundColor: Colors.orange, // Button background color
                      foregroundColor: Colors.white, // Button text color
                      elevation: 5, // Elevated effect
                    ),
                    onPressed: () {
                      firestore.collection('subjects').doc(subjectId).update({
                        'notAttendedPractical': FieldValue.increment(1),
                      });
                      Fluttertoast.showToast(msg: 'Practical Marked as Missed');
                    },
                    child: const Text(
                      'Mark Practical as Missed',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                  const SizedBox(width: 10), // Space between buttons

                  // Undo Button for Practical Missed
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.orange.shade100),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.remove, color: Colors.orange),
                      onPressed: () {
                        decrementAttendance('notAttendedPractical');
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
