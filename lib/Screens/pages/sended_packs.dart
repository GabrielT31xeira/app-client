import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class SendedPage extends StatefulWidget {
  @override
  _SendedPageState createState() => _SendedPageState();
}

class _SendedPageState extends State<SendedPage> {
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
    final url = Uri.parse('http://35.174.5.208:83/api/travel/$id/send');
    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    print(response.body);
    if (response.statusCode == 200) {
      setState(() {
        travels = json.decode(response.body)['travel'];
      });
    } else {
      throw Exception('Failed to load packages');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Listagem de Pacotes Aceitos'),
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
            final user = travel['user'];
            final proposals = user != null ? user['proposals'] : null;
            final carrier = proposals != null && proposals.isNotEmpty ? proposals[0] : null;
            final carrierUser = carrier != null ? carrier['user'] : null;

            return Card(
              margin: EdgeInsets.all(10),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (carrierUser != null) ...[
                      SizedBox(height: 5),
                      Text('Motorista: ${carrierUser['user']['name']}', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text('E-mail: ${carrierUser['user']['email']}'),
                    ],
                    if (carrier != null) ...[
                      Text('Data de Saída: ${carrier['date_output']}'),
                      Text('Data de Entrega: ${carrier['date_arrival']}'),
                      Text('Saída do Motorista: ${carrier['output_city']} - ${carrier['output_state']}'),
                      Text('Chegada do Motorista: ${carrier['arrival_city']} - ${carrier['arrival_state']}'),
                      Text('Veículo: ${carrier['vehicle_type']} - Placa ${carrier['vehicle_plate']}'),
                      Text('Marca: ${carrier['vehicle_brand']} - Ano ${carrier['vehicle_model_year']}'),
                      Text('Valor da Entrega: ${carrier['price']} R\$'),
                    ],
                    if (package != null) ...[
                      SizedBox(height: 10),
                      Text('Pacote: ${package['description']}', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text('Peso: ${package['weight']} ${package['metric_weight']}'),
                      Text('Dimensões: ${package['width']} ${package['metric_width']} x ${package['height']} ${package['metric_height']}'),
                      Text('Fragilidade: ${package['fragility']}'),
                    ],
                    Text('Saida do Pacote: ${travel['arrival']['city']} - ${travel['arrival']['state']}'),
                    Text('Chegada do Pacote: ${travel['output']['city']} - ${travel['output']['state']}'),
                    SizedBox(height: 10),
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