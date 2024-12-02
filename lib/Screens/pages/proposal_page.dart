import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class ProposalPage extends StatefulWidget {
  final String travelId;

  ProposalPage({required this.travelId});

  @override
  _ProposalPageState createState() => _ProposalPageState();
}

class _ProposalPageState extends State<ProposalPage> {
  List<dynamic> proposal = [];

  @override
  void initState() {
    super.initState();
    fetchProposal();
  }

  Future<void> fetchProposal() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final url = Uri.parse('http://54.205.181.130:84/api/proposal/${widget.travelId}/travel');
    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      setState(() {
        proposal = json.decode(response.body)['proposals'];
      });

    } else {
      throw Exception('Failed to load travels');
    }
  }

  Future<void> acceptProposal(String proposalId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final url = Uri.parse('http://54.205.181.130:84/api/proposal/$proposalId/accept');
    final response = await http.put(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    print(response.body);
    if (response.statusCode == 200) {
      setState(() {
        fetchProposal();
        _showSucess(context);
      });
    } else {
      _showError(context);
      throw Exception('Failed to load Proposals');
    }
  }

  void _showSucess(BuildContext context) {
    Fluttertoast.showToast(
      msg: "Proposta aceita com sucesso!",
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
        title: Text('Propostas Enviadas'),
        backgroundColor: Colors.orange,
      ),
      body: Column(
        children: [
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: proposal.isEmpty
                      ? Center(child: Text('Sem propostas enviadas'))
                      : ListView.builder(
                    itemCount: proposal.length,
                    itemBuilder: (context, index) {
                      return Card(
                        margin: EdgeInsets.all(10),
                        child: Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Motorista: ${proposal[index]['user']['user']['name']}', style: TextStyle(fontWeight: FontWeight.bold)),
                              Text('Placa do Veículo: ${proposal[index]['vehicle_plate']}', style: TextStyle(fontWeight: FontWeight.bold)),
                              Text('Tipo de Veículo: ${proposal[index]['vehicle_type']}'),
                              Text('Marca: ${proposal[index]['vehicle_brand']}'),
                              Text('Modelo: ${proposal[index]['vehicle_model']} (${proposal[index]['vehicle_model_year']})'),
                              SizedBox(height: 10),
                              Text('Saída: ${proposal[index]['output_city']}, ${proposal[index]['output_state']}'),
                              Text('Endereço de Saída: ${proposal[index]['output_address']}'),
                              Text('Data de Saída: ${proposal[index]['date_output']}'),
                              SizedBox(height: 10),
                              Text('Chegada: ${proposal[index]['arrival_city']}, ${proposal[index]['arrival_state']}'),
                              Text('Endereço de Chegada: ${proposal[index]['arrival_address']}'),
                              Text('Data de Chegada: ${proposal[index]['date_arrival']}'),
                              SizedBox(height: 10),
                              Text('Preço: R\$${proposal[index]['price']}'),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  SizedBox(width: 10),
                                  TextButton(
                                    onPressed: () {
                                      acceptProposal(proposal[index]['id_proposal']);
                                    },
                                    child: Text('Aceitar Proposta', style: TextStyle(color: Colors.blue)),
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}