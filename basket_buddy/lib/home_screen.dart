import 'package:basket_buddy/shopping_list_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:basket_buddy/item_detail_screen.dart';

import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  int _selectedIndex = 0;
  String? userId = FirebaseAuth.instance.currentUser?.uid;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.brown[200],
      appBar: AppBar(
        title: const Text('Home Screen'),
          backgroundColor: Colors.brown[400],
          surfaceTintColor: Colors.brown[400],
          foregroundColor: Colors.white,
          elevation: 0,

      ),

      body: Padding(

        padding: const EdgeInsets.symmetric(vertical: 20),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('users').doc(userId).collection('items').snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(child: Text('No data available'));
            } else {
              List<String> documentNames = snapshot.data!.docs.map((doc) => doc.id).toList();
              return ListView.builder(
                itemCount: documentNames.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => ItemDetailScreen(name: documentNames[index])));
                    },
                    child: SizedBox(
                      height: MediaQuery.of(context).size.height * 0.15,
                      child: Card(
                        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        elevation:  10,
                        color: Colors.brown[400],
                        surfaceTintColor: Colors.brown[300],
                        child: Center(
                          child: ListTile(
                            leading: CircleAvatar(
                              child: Text('${index + 1}'),
                              backgroundColor: Colors.brown[300],
                              foregroundColor: Colors.white,
                            ),
                            title: Padding(
                              padding: const EdgeInsets.only(left: 20),
                              child: Text(documentNames[index], style: TextStyle(color: Colors.white, fontSize: 20),),
                            ),
                            trailing: IconButton(
                              onPressed: () {
                                deleteItem(documentNames[index]);
                              },
                              icon: const Icon(Icons.delete, color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            }
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddItemDialog(context);
        },
        child: const Icon(Icons.add),
        backgroundColor: Colors.brown[400],
        foregroundColor: Colors.white,
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            //backgroundColor: Colors.white10,
            icon: Icon(
              Icons.home,
              color: Colors.brown[400],
            ),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.add_shopping_cart,
              color: Colors.brown[400],
            ),
            label: 'Shpping List',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.logout,
              color: Colors.brown[400],
            ),
            label: 'Logout',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.brown[400],
        onTap: _onItemTapped,
        elevation: 5,
        iconSize: 25,
        type: BottomNavigationBarType.shifting,
      ),
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    if (_selectedIndex == 0) {
      // Navigate to the HomeScreen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => HomeScreen(),
        ),
      );
    } else if (_selectedIndex == 1) {
      // Navigate to the ShoppingListScreen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ShoppingListScreen(),
        ),
      );
    }else if (_selectedIndex == 2){
      signout();
    }
  }

  void signout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
    );
  }
  void deleteItem(String documentName) async {
    FirebaseFirestore.instance.collection('users').doc(userId).collection('items').doc(documentName).delete();
  }

  void addItem(String item) async {
    FirebaseFirestore.instance.collection('users').doc(userId).collection('items').doc(item).set({});
    print('Document added successfully!');
  }

  void _showAddItemDialog(BuildContext context) {
    TextEditingController nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.brown[300],
          title: Text("Add Item", style: TextStyle(color: Colors.white),),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(
                controller: nameController,
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(labelText: 'Name', labelStyle: TextStyle(color: Colors.white), focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white))),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: Text("Cancel", style: TextStyle(color: Colors.white),),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text("Add", style: TextStyle(color: Colors.white),),
              onPressed: () {
                String name = nameController.text.trim();
                if (name.isNotEmpty) {
                  addItem(name);
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

}