import 'dart:convert';
import 'dart:ffi';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_cloud_firestore/firebase_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ItemDetailScreen extends StatefulWidget {
  const ItemDetailScreen({required this.name, super.key});
  final String name;

  @override
  State<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends State<ItemDetailScreen> {
  String? _selectedUnit;
  String? _enteredName;
  double _remainingStock = 0.0;
  final double _maxRemainingStock = 100.0;
  List<Map<String, dynamic>> _addedData = [];
  double _enteredPrice = 0.0;
  DateTime _selectedDate = DateTime.now();

  final List<String> _units = ['Unit', 'Kg', 'Gram', 'Liter', 'Milliliter'];
  String? userId = FirebaseAuth.instance.currentUser?.uid;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.brown[200],
      appBar: AppBar(
        title: Text('Manage ${widget.name}'),
        backgroundColor: Colors.brown[400],
        surfaceTintColor: Colors.brown[400],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance.collection('users').doc(userId).collection('items').doc(widget.name).snapshots(),
          builder: (BuildContext context, AsyncSnapshot<DocumentSnapshot<Map<String, dynamic>>> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            List<Map<String, dynamic>> itemList = [];
            var data = snapshot.data?.data();
            if (data != null && data['data'] != null) {
              itemList = List<Map<String, dynamic>>.from(data['data'] as List<dynamic>);
            }

            return ListView.builder(
              itemCount: itemList.length,
              itemBuilder: (context, index) {
                Map<String, dynamic> item = itemList[index];
                return Card(
                  elevation: 10,
                  margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  color: Colors.brown[400],
                  surfaceTintColor: Colors.brown[300],
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              child: Text('${index + 1}'),
                              backgroundColor: Colors.brown[300],
                              foregroundColor: Colors.white,
                            ),
                            SizedBox(width: 20,),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Item: ${item['name'] ?? ''}', style: TextStyle(color: Colors.white),),
                                Text('Quantity: ${item['quantity'] ?? ''}', style: TextStyle(color: Colors.white)),
                                Text('Price: ${item['price'] ?? ''}rs', style: TextStyle(color: Colors.white)),
                                Text('Remaining Stock: ${double.parse(item['remainingStock'].toString()).toStringAsPrecision(3) ?? ''}%', style: TextStyle(color: Colors.white)),
                                Text('Unit: ${item['size'] ?? ''}', style: TextStyle(color: Colors.white)),
                                Text('Date: ${item['date'] ?? ''}', style: TextStyle(color: Colors.white)),
                              ],
                            ),
                          ],
                        ),
                        IconButton(onPressed: (){
                          deleteItem(item);
                        }, icon: Icon(Icons.delete, color: Colors.white,))
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.brown[400],
        foregroundColor: Colors.white,
        onPressed: () {
          showModalBottomSheet(
            backgroundColor: Colors.brown[200],
            context: context,
            builder: (BuildContext context) {
              return SingleChildScrollView(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Name:', style: TextStyle(fontSize: 20)),
                      TextFormField(
                        onChanged: (value) {
                          setState(() {
                            _enteredName = value;
                          });
                        },
                      ),
                      const SizedBox(height: 10),
                      const Text('Size:', style: TextStyle(fontSize: 20)),
                      DropdownButtonFormField(
                        value: _selectedUnit,
                        items: _units.map((String unit) {
                          return DropdownMenuItem(
                            value: unit,
                            child: Text(unit),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedUnit = value.toString();
                          });
                        },
                      ),
                      const SizedBox(height: 10),
                      const Text('Remaining Stock:', style: TextStyle(fontSize: 20)),
                      Slider(
                        value: _remainingStock,
                        min: 0,
                        max: _maxRemainingStock,
                        onChanged: (value) {
                          setState(() {
                            _remainingStock = value;
                          });
                        },
                      ),
                      const SizedBox(height: 10),
                      const Text('Price:', style: TextStyle(fontSize: 20)),
                      TextFormField(
                        onChanged: (value) {
                          setState(() {
                            _enteredPrice = double.parse(value); // Update entered price
                          });
                        },
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      ),
                      const SizedBox(height: 10),
                      const Text('Date:', style: TextStyle(fontSize: 20)),
                      ElevatedButton(
                        onPressed: () {
                          _selectDate(context);
                        },
                        child: const Text('Select Date'),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          ElevatedButton(
                            onPressed: () async {
                              Map<String, dynamic> data = {
                                'name': _enteredName,
                                'quantity': 0,
                                'size': _selectedUnit ?? '',
                                'remainingStock': _remainingStock,
                                'price': _enteredPrice,
                                'date': DateFormat('d MMMM y').format(_selectedDate),
                              };
                              String? user = await FirebaseAuth.instance.currentUser?.uid;
                              FirebaseFirestore.instance.collection('users').doc(user).collection('items').doc(widget.name).update({
                                'data': FieldValue.arrayUnion([data])
                              });
                              Navigator.pop(context);
                            },
                            child: const Text('Add'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void deleteItem(Map<String, dynamic> item) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('items')
        .doc(widget.name)
        .update({
      'data': FieldValue.arrayRemove([item])
    });
  }
}
