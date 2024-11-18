import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class SearchPage extends StatefulWidget {
  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _cityControllerStart = TextEditingController();
  final _stateControllerStart = TextEditingController();
  final _addressControllerStart = TextEditingController();

  final _cityControllerEnd = TextEditingController();
  final _stateControllerEnd = TextEditingController();
  final _addressControllerEnd = TextEditingController();

  final _widthController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final _fragilityController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _selectedMetricWidth = 'cm';
  String _selectedMetricHeight = 'cm';
  String _selectedMetricWeight = 'kg';

  late GoogleMapController _mapController;
  LatLng? _startLocation;
  LatLng? _endLocation;
  Set<Polyline> _polylines = {};

  bool _isStartSet = false;
  bool _isEndSet = false;

  Map<String, dynamic> _packageData = {
    'pacote': {},
    'saida': {},
    'chegada': {},
  };

  void _showInputDialog(BuildContext context, bool isStart) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title:
              Text(isStart ? 'Informações de Saída' : 'Informações de Destino'),
          content: Container(
            width: MediaQuery.of(context).size.width * 0.8,
            height: MediaQuery.of(context).size.height * 0.5,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller:
                        isStart ? _cityControllerStart : _cityControllerEnd,
                    decoration: InputDecoration(
                      labelText: 'Cidade',
                      labelStyle: TextStyle(color: Color(0xFFFF7E26)),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFFFF7E26)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFFFF7E26)),
                      ),
                    ),
                  ),
                  SizedBox(height: 10),
                  TextField(
                    controller:
                        isStart ? _stateControllerStart : _stateControllerEnd,
                    decoration: InputDecoration(
                      labelText: 'Estado',
                      labelStyle: TextStyle(color: Color(0xFFFF7E26)),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFFFF7E26)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFFFF7E26)),
                      ),
                    ),
                  ),
                  SizedBox(height: 10),
                  TextField(
                    controller: isStart
                        ? _addressControllerStart
                        : _addressControllerEnd,
                    decoration: InputDecoration(
                      labelText: 'Endereço',
                      labelStyle: TextStyle(color: Color(0xFFFF7E26)),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFFFF7E26)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFFFF7E26)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancelar'),
              style: TextButton.styleFrom(foregroundColor: Color(0xFFFF7E26)),
            ),
            ElevatedButton(
              onPressed: () async {
                setState(() {
                  if (isStart) {
                    _packageData['saida'] = {
                      'cidade': _cityControllerStart.text,
                      'estado': _stateControllerStart.text,
                      'endereco': _addressControllerStart.text,
                    };
                    _isStartSet = true;
                  } else {
                    _packageData['chegada'] = {
                      'cidade': _cityControllerEnd.text,
                      'estado': _stateControllerEnd.text,
                      'endereco': _addressControllerEnd.text,
                    };
                    _isEndSet = true;
                  }
                });
                Navigator.of(context).pop();
                await _searchAddress(isStart);
              },
              child: Text('Confirmar'),
              style:
                  ElevatedButton.styleFrom(backgroundColor: Color(0xFFFF7E26)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _searchAddress(bool isStart) async {
    String city = isStart ? _cityControllerStart.text : _cityControllerEnd.text;
    String state =
        isStart ? _stateControllerStart.text : _stateControllerEnd.text;
    String address =
        isStart ? _addressControllerStart.text : _addressControllerEnd.text;
    try {
      List<Location> locations =
          await locationFromAddress('$address, $city, $state');
      if (locations.isNotEmpty) {
        final location = locations.first;
        setState(() {
          if (isStart) {
            _startLocation = LatLng(location.latitude, location.longitude);
            _packageData['saida'] = {
              'latitude': location.latitude,
              'longitude': location.longitude,
              'cidade': city,
              'estado': state,
              'endereco': address
            };
          } else {
            _endLocation = LatLng(location.latitude, location.longitude);
            _packageData['chegada'] = {
              'latitude': location.latitude,
              'longitude': location.longitude,
              'cidade': city,
              'estado': state,
              'endereco': address
            };
            _drawRoute();
          }
        });
        _mapController.animateCamera(CameraUpdate.newLatLng(
            LatLng(location.latitude, location.longitude)));
      } else {
        _showError(context);
      }
    } catch (e) {
      print('Erro ao buscar o endereço: $e');
      _showError(context);
    }
  }

  Future<void> _drawRoute() async {
    if (_startLocation != null && _endLocation != null) {
      String url = 'https://maps.googleapis.com/maps/api/directions/json'
          '?origin=${_startLocation!.latitude},${_startLocation!.longitude}'
          '&destination=${_endLocation!.latitude},${_endLocation!.longitude}'
          '&key=AIzaSyBscAm8DFRRyyGsyCWcINDhYt03PYmPwDg';

      var response = await http.get(Uri.parse(url));
      var data = json.decode(response.body);

      if (data['status'] == 'OK') {
        List<PointLatLng> points =
            _decodePolyline(data['routes'][0]['overview_polyline']['points']);
        PolylineId id = PolylineId('route');
        Polyline polyline = Polyline(
          polylineId: id,
          color: Color(0xFFFF7E26),
          points: points
              .map((point) => LatLng(point.latitude, point.longitude))
              .toList(),
          width: 5,
        );
        setState(() {
          _polylines.add(polyline);
        });
      } else {
        print('Erro ao buscar o endereço: $data');
        _showError(context);
      }
    }
  }

  List<PointLatLng> _decodePolyline(String encoded) {
    List<PointLatLng> points = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      points.add(PointLatLng((lat / 1E5).toDouble(), (lng / 1E5).toDouble()));
    }

    return points;
  }

  Future<void> sendPackage(package) async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString('user_id');
    final token = prefs.getString('token');
    final url = Uri.parse('http://35.174.5.208:83/api/travel/$id/store');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },

      body: jsonEncode(package),
    );
    if (response.statusCode == 200) {
      _showSucess(context);
    } else {
      _showError(context);
      print('Erro ao enviar pacote: ${response.statusCode}');
    }
  }

  void _showSucess(BuildContext context) {
    Fluttertoast.showToast(
      msg: "Pacote cadastrado com sucesso, buscando motoristas!",
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

  void _showPackageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Adicionar Pacote'),
          content: Container(
            width: MediaQuery.of(context).size.width * 0.8,
            height: MediaQuery.of(context).size.height * 0.7,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: _widthController,
                          decoration: InputDecoration(
                            labelText: 'Largura',
                            labelStyle: TextStyle(color: Colors.orange),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.orange),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.orange),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        flex: 1,
                        child: DropdownButtonFormField<String>(
                          value: _selectedMetricWidth,
                          items: ['cm', 'm'].map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            _selectedMetricWidth = newValue!;
                          },
                          decoration: InputDecoration(
                            labelText: 'Métrica',
                            labelStyle: TextStyle(color: Colors.orange),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.orange),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.orange),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: _heightController,
                          decoration: InputDecoration(
                            labelText: 'Altura',
                            labelStyle: TextStyle(color: Colors.orange),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.orange),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.orange),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        flex: 1,
                        child: DropdownButtonFormField<String>(
                          value: _selectedMetricHeight,
                          items: ['cm', 'm'].map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            _selectedMetricHeight = newValue!;
                          },
                          decoration: InputDecoration(
                            labelText: 'Métrica',
                            labelStyle: TextStyle(color: Colors.orange),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.orange),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.orange),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: _weightController,
                          decoration: InputDecoration(
                            labelText: 'Peso',
                            labelStyle: TextStyle(color: Colors.orange),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.orange),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.orange),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        flex: 1,
                        child: DropdownButtonFormField<String>(
                          value: _selectedMetricWeight,
                          items: ['kg', 'g'].map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            _selectedMetricWeight = newValue!;
                          },
                          decoration: InputDecoration(
                            labelText: 'Métrica',
                            labelStyle: TextStyle(color: Colors.orange),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.orange),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.orange),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  TextField(
                    controller: _fragilityController,
                    decoration: InputDecoration(
                      labelText: 'Fragilidade',
                      labelStyle: TextStyle(color: Colors.orange),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.orange),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.orange),
                      ),
                    ),
                  ),
                  SizedBox(height: 10),
                  TextField(
                    controller: _descriptionController,
                    decoration: InputDecoration(
                      labelText: 'Descrição',
                      labelStyle: TextStyle(color: Colors.orange),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.orange),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.orange),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancelar'),
              style: TextButton.styleFrom(foregroundColor: Colors.orange),
            ),
            ElevatedButton(
              onPressed: () {
                _packageData['pacote']['largura'] = _widthController.text;
                _packageData['pacote']['altura'] = _heightController.text;
                _packageData['pacote']['peso'] = _weightController.text;
                _packageData['pacote']['fragilidade'] = _fragilityController.text;
                _packageData['pacote']['descricao'] = _descriptionController.text;
                _packageData['pacote']['metrica_largura'] = _selectedMetricWidth;
                _packageData['pacote']['metrica_altura'] = _selectedMetricHeight;
                _packageData['pacote']['metrica_peso'] = _selectedMetricWeight;
                sendPackage(_packageData);
                Navigator.of(context).pop();
              },
              child: Text('Confirmar'),
              style: ElevatedButton.styleFrom(foregroundColor: Colors.orange),
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
          title: Text('Enviar pacote'),
          backgroundColor: Colors.white,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pushNamed(context, '/home'),
          ),
        ),
        body: Stack(children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: LatLng(-23.550520, -46.633308),
              zoom: 10,
            ),
            zoomControlsEnabled: false,
            onMapCreated: (GoogleMapController controller) {
              _mapController = controller;
            },
            markers: {
              if (_startLocation != null)
                Marker(
                  markerId: MarkerId('startLocation'),
                  position: _startLocation!,
                  infoWindow: InfoWindow(title: 'Ponto de Partida'),
                ),
              if (_endLocation != null)
                Marker(
                  markerId: MarkerId('endLocation'),
                  position: _endLocation!,
                  infoWindow: InfoWindow(title: 'Ponto de Destino'),
                ),
            },
            polylines: _polylines,
          ),
          Positioned(
            bottom: 20.0,
            left: 16.0,
            right: 16.0,
            child: Column(
              children: [
                if (_isStartSet && _isEndSet)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        _showPackageDialog(context);
                      },
                      child: Text('Adicionar Pacote',
                          style: TextStyle(color: Colors.orange)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                            horizontal: 16.0, vertical: 12.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0),
                          side: BorderSide(color: Colors.orange),
                        ),
                      ),
                    ),
                  ),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        _showInputDialog(context, true);
                      },
                      icon: Icon(Icons.location_on, color: Colors.white),
                      label: Text('Ponto de Partida',
                          style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFFFF7E26),
                        padding: EdgeInsets.symmetric(
                            horizontal: 16.0, vertical: 12.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        _showInputDialog(context, false);
                      },
                      icon: Icon(Icons.location_on, color: Colors.white),
                      label: Text('Ponto de Destino',
                          style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFFFF7E26),
                        padding: EdgeInsets.symmetric(
                            horizontal: 16.0, vertical: 12.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          )
        ]));
  }
}

class PointLatLng {
  final double latitude;
  final double longitude;

  PointLatLng(this.latitude, this.longitude);
}
