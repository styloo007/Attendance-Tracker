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
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      Fluttertoast.showToast(msg: 'Login Successful');
    } catch (e) {
      Fluttertoast.showToast(msg: 'Login Failed: ${e.toString()}');
    }

    setState(() {
      isLoading = false;
    });
  }

  Future<void> _register() async {
    setState(() {
      isLoading = true;
    });

    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      Fluttertoast.showToast(msg: 'Registration Successful');
    } catch (e) {
      Fluttertoast.showToast(msg: 'Registration Failed: ${e.toString()}');
    }

    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('')),
      body: SingleChildScrollView(
        // Wrap the Column in SingleChildScrollView
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, // Align to the start
          children: [
            // Main Title for the app
            const Text(
              'My Attendance Tracker',
              style: TextStyle(
                fontSize: 32, // Increase the font size for the title
                fontWeight: FontWeight.bold,
                color: Colors.blue, // You can change the color as needed
              ),
            ),
            const SizedBox(
                height:
                    40), // Add some spacing between the title and 'Login/Register'

            // Sub-title for Login/Register
            const Text(
              'Login/Register',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: Colors.black, // You can adjust the color here
              ),
            ),
            const SizedBox(
                height:
                    20), // Add some spacing between the 'Login/Register' text and form fields

            // Email text field
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 10), // Add spacing between input fields

            // Password text field
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            const SizedBox(height: 20),

            // Loading indicator or Login/Register buttons
            if (isLoading)
              const CircularProgressIndicator()
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: _login,
                    child: const Text('Login'),
                  ),
                  ElevatedButton(
                    onPressed: _register,
                    child: const Text('Register'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

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
          height: 400, // Set fixed height for the dialog
          width: 300,
          child: SingleChildScrollView(
            // Wrapping with SingleChildScrollView
            child: TableCalendar(
              firstDay: DateTime.utc(2000, 1, 1),
              lastDay: DateTime.utc(2100, 12, 31),
              focusedDay: DateTime.now(),
              headerStyle: const HeaderStyle(
                formatButtonVisible: false, // Hides the "2 weeks" button
              ),
              onFormatChanged: (format) {
                // Format change logic can be added here
              },
            ),
          ),
        ),
      ),
    );
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
      body: StreamBuilder<QuerySnapshot>(
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
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Row(
                          children: [
                            const Text('Theory Attendance: ',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            Text(theoryPercentage,
                                style: const TextStyle(color: Colors.green)),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Row(
                          children: [
                            const Text('Practical Attendance: ',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            Text(practicalPercentage,
                                style: const TextStyle(color: Colors.green)),
                          ],
                        ),
                      ),
                      const Divider(),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Row(
                          children: [
                            const Text('Theory Attended: ',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            Text('${subject['attendedTheory']}'),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Row(
                          children: [
                            const Text('Theory Missed: ',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            Text('${subject['notAttendedTheory']}'),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Row(
                          children: [
                            const Text('Practical Attended: ',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            Text('${subject['attendedPractical']}'),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Row(
                          children: [
                            const Text('Practical Missed: ',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            Text('${subject['notAttendedPractical']}'),
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
                              SubjectManagementScreen(subjectId: subject.id),
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
              const CircularProgressIndicator()
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
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(200, 50),
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
              const SizedBox(height: 20), // Spacing between buttons

              // Mark Theory Missed Button
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(200, 50),
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
              const SizedBox(height: 20), // Spacing between buttons

              // Mark Practical Attendance Button
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(200, 50),
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
                  Fluttertoast.showToast(msg: 'Practical Marked as Attended');
                },
                child: const Text(
                  'Mark Practical as Attended',
                  style: TextStyle(fontSize: 16),
                ),
              ),
              const SizedBox(height: 20), // Spacing between buttons

              // Mark Practical Missed Button
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(200, 50),
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
            ],
          ),
        ),
      ),
    );
  }
}
