import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ShoppingListScreen extends StatefulWidget {
  const ShoppingListScreen({Key? key}) : super(key: key);

  @override
  State<ShoppingListScreen> createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends State<ShoppingListScreen> {
  String? userId = FirebaseAuth.instance.currentUser?.uid;
  double totalBudget = 0.0;
  double userSetBudget = 0.0; // Added
  String? name1;
  double totalExpense = 0.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Shopping List'),
        actions: [
          IconButton(
            onPressed: () {
              _showSetBudgetDialog(context);
            },
            icon: Icon(Icons.settings),
          ),
        ],
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('collections')
            .snapshots(),
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.data == null || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No data available'));
          }

          // Calculate total budget
          totalBudget = snapshot.data!.docs.fold<double>(
            0.0,
                (previousValue, doc) {
              Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
              List<dynamic> dataArray = data['data'];
              double totalPrice = dataArray.fold<double>(
                0.0,
                    (previousValue, item) => previousValue + (item['price'] ?? 0.0) * (item['quantity'] ?? 0.0),
              );
              return previousValue + totalPrice;
            },
          );

          // Calculate total expense
          totalExpense = snapshot.data!.docs.fold<double>(
            0.0,
                (previousValue, doc) {
              Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
              List<dynamic> dataArray = data['data'];
              double totalPrice = dataArray.fold<double>(
                0.0,
                    (previousValue, item) => previousValue + (item['price'] ?? 0.0) * (item['quantity'] ?? 0.0),
              );
              return previousValue + totalPrice;
            },
          );

          // Calculate remaining budget
          double remainingBudget = userSetBudget - totalExpense; // Changed

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    DocumentSnapshot doc = snapshot.data!.docs[index];
                    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
                    List<dynamic> dataArray = data['data'];

                    return Card(
                      child: ListTile(
                        title: Text('Item ${index + 1}'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: dataArray.map<Widget>((item) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Name: ${item['name']}'),
                                Text('Unit: ${item['unit']}'),
                                Text('Price: ${item['price']}'),
                                Text('Quantity: ${item['quantity']}'),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Total Budget: ₹${(totalExpense+remainingBudget).toStringAsFixed(2)}',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Total Expense: ₹${totalExpense.toStringAsFixed(2)}',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Remaining Budget: ₹${remainingBudget.toStringAsFixed(2)}',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddItemDialog(context);
        },
        child: Icon(Icons.add),
      ),
    );
  }

  void _showSetBudgetDialog(BuildContext context) {
    TextEditingController budgetController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Set Budget'),
          content: TextField(
            controller: budgetController,
            decoration: InputDecoration(labelText: 'Budget'),
            keyboardType: TextInputType.number,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                double newBudget = double.tryParse(budgetController.text) ?? 0.0;

                if (newBudget >= 0) {
                  setState(() {
                    userSetBudget = newBudget;
                  });
                  Navigator.pop(context);
                } else {
                  // Show error message if budget is negative
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Please enter a non-negative value for budget.'),
                    ),
                  );
                }
              },
              child: Text('Set'),
            ),
          ],
        );
      },
    );
  }

  void _showAddItemDialog(BuildContext context) {
    TextEditingController nameController = TextEditingController();
    TextEditingController unitController = TextEditingController();
    TextEditingController priceController = TextEditingController();
    TextEditingController quantityController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Add Shopping Item'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(labelText: 'Name'),
                ),
                TextField(
                  controller: unitController,
                  decoration: InputDecoration(labelText: 'Unit'),
                ),
                TextField(
                  controller: priceController,
                  decoration: InputDecoration(labelText: 'Price'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: quantityController,
                  decoration: InputDecoration(labelText: 'Quantity'),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                name1 = nameController.text;
                String unit = unitController.text;
                double price = double.tryParse(priceController.text) ?? 0.0;
                double quantity = double.tryParse(quantityController.text) ?? 0.0;

                if (name1!.isNotEmpty && unit.isNotEmpty && price > 0 && quantity > 0) {
                  final data = {
                    'name': name1,
                    'unit': unit,
                    'price': price,
                    'quantity': quantity
                  };
                  FirebaseFirestore.instance.collection('users').doc(userId).collection('collections').doc(name1).set({
                    'data': FieldValue.arrayUnion([data])
                  });
                  Navigator.pop(context);
                } else {
                  // Show error message if any field is empty or invalid
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Please fill all fields with valid values.'),
                    ),
                  );
                }
              },
              child: Text('Add'),
            ),
          ],
        );
      },
    );
  }
}

