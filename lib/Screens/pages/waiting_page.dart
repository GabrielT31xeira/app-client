import 'package:client/Screens/pages/package_details_page.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class WaitingPage extends StatefulWidget {
  @override
  _WaitingPageState createState() => _WaitingPageState();
}

class _WaitingPageState extends State<WaitingPage> {
  List<dynamic> travels = [];

  @override
  void initState() {
    super.initState();
    fetchPackages();
  }

  Future<void> fetchPackages() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString('user_id');
    final token = prefs.getString('token');
    final url = Uri.parse('http://35.174.5.208:83/api/travel/$id/unsend');
    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      setState(() {
        travels = json.decode(response.body)['travel'];
      });
    } else {
      throw Exception('Failed to load packages');
    }
  }

  Future<void> deletePackages(String packageId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final url = Uri.parse('http://35.174.5.208:83/api/travel/$packageId');
    final response = await http.delete(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      setState(() {
        travels.removeWhere((package) => package['id_travel'] == packageId);
        _showSucess(context);
      });
    } else {
      _showError(context);
      throw Exception('Failed to load packages');
    }
  }

  void _showSucess(BuildContext context) {
    Fluttertoast.showToast(
      msg: "Pacote apagado com sucesso!",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.TOP,
      timeInSecForIosWeb: 1,
      backgroundColor: Colors.green,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  void _showError(BuildContext context) {
    Fluttertoast.showToast(
      msg: "Erro por parte do servidor, tente novamente mais tarde!",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.TOP,
      timeInSecForIosWeb: 1,
      backgroundColor: Colors.redAccent,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Listagem de Pacotes'),
        backgroundColor: Colors.orange,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pushNamed(context, '/home'),
        ),
      ),
      body: Container(
        color: Colors.orange[50],
        child: travels.isEmpty
            ? Center(child: CircularProgressIndicator())
            : ListView.builder(
          itemCount: travels.length,
          itemBuilder: (context, index) {
            final travel = travels[index];
            final package = travel['package'];

            return Card(
              margin: EdgeInsets.all(10),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Pacote: ${package['description']}', style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(height: 5),
                    Text('Peso: ${package['weight']} ${package['metric_weight']}'),
                    Text('Dimensões: ${package['width']} ${package['metric_width']} x ${package['height']} ${package['metric_height']}'),
                    Text('Fragilidade: ${package['fragility']}'),
                    Text('Saida: ${travel['arrival']['city']}, ${travel['arrival']['state']}'),
                    Text('Chegada: ${travel['output']['city']}, ${travel['output']['state']}'),
                    SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () {
                            deletePackages(travel['id_travel']);
                          },
                          child: Text('Apagar', style: TextStyle(color: Colors.red)),
                        ),
                        SizedBox(width: 10),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PackageDetailsPage(travelId: travel['id_travel']),
                              ),
                            );
                          },
                          child: Text('Detalhes', style: TextStyle(color: Colors.blue)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
