import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ClimaHomepage extends StatefulWidget {
  const ClimaHomepage({super.key});

  @override
  State<ClimaHomepage> createState() => _ClimaHomepageState();
}

class _ClimaHomepageState extends State<ClimaHomepage> {
  final TextEditingController _controller = TextEditingController();
  String _ciudad = '';
  String _description = '';
  String? _temperatura;
  String _iconoUrl = '';
  bool _cargando = false;
  bool _usarFahrenheit = false;
  List<String> _favoritas = [];

  @override
  initState() {
    super.initState();
    _cargarCiudadGuardada();
    _cargarPreferenciaUnidadTemperatura();
    _cargarCiudadesFavoritas();
  }

  Future<void> obtenerClima(String ciudad) async {
    if (ciudad.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Ingrese una ciudad.')));
      return;
    }

    setState(() {
      _cargando = true;
    });

    final unidades = _usarFahrenheit ? 'imperial' : 'metric';
    final apiKey = "3c5c7cd19d1e7b84c8e3bbf91d3174c5";
    final urlClima =
        'https://api.openweathermap.org/data/2.5/weather?q=$ciudad&appid=$apiKey&units=$unidades&lang=es';
    final response = await http.get(Uri.parse(urlClima));

    try {
      if (response.statusCode == 200) {
        final datos = json.decode(response.body);
        setState(() {
          _description = datos['weather'][0]['description'].toString();
          _iconoUrl =
              'https://openweathermap.org/img/wn/${datos['weather'][0]['icon']}@2x.png';
          _temperatura = datos['main']['temp'].toString();
          _ciudad = datos['name'].toString();
        });
      } else {
        _description = "La ciudad $ciudad no fue encontrada.";
        _iconoUrl = "";
        _temperatura = null;
      }
    } catch (e) {
      setState(() {
        _description = "Error de conexion.  ${response.statusCode}";
        _iconoUrl = "";
        _temperatura = null;
      });
    }
    setState(() {
      _cargando = false;
    });
  }

  Future<void> _guardarCiudadesFavoritas() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('favoritas', _favoritas);
  }

  Future<void> _cargarCiudadesFavoritas() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _favoritas = prefs.getStringList('favoritas') ?? [];
    });
  }

  Column generaRespuesta() {
    var estiloTitulo = TextStyle(
      color: Colors.black,
      fontSize: 24,
      fontWeight: FontWeight.bold,
      fontFamily: "Arial",
    );
    var estiloDescripcion = TextStyle(
      color: Colors.blueGrey,
      fontSize: 20,
      fontWeight: FontWeight.w700,
      fontStyle: FontStyle.italic,
      fontFamily: "Arial Narrow",
    );
    var estiloTemperatura = TextStyle(
      color: Colors.black12,
      fontSize: 48,
      fontWeight: FontWeight.w300,
      fontStyle: FontStyle.normal,
    );

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,

      children: [
        if (_ciudad.isNotEmpty)
          Text('Clima en ciudad $_ciudad', style: estiloTitulo),
        if (_temperatura != null)
          Text(
            '$_temperatura ${_usarFahrenheit ? '°F' : '°C'}',
            style: estiloTemperatura,
          ),
        if (_description.isNotEmpty)
          Text(_description, style: estiloDescripcion),
        if (_iconoUrl.isNotEmpty)
          Image.network(_iconoUrl, height: 100, color: Colors.blueAccent),
        if (_ciudad.isNotEmpty) agregarCiudadButton(),
      ],
    );
  }

  ElevatedButton agregarCiudadButton() => ElevatedButton.icon(
    onPressed: () {
      if (!_favoritas.contains(_ciudad)) {
        setState(() {
          _favoritas.add(_ciudad);
        });
        _guardarCiudadesFavoritas();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$_ciudad, fue agregada exitosamente.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '$_ciudad, ya existe en favoritos.',
              style: TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      }
    },
    icon: Icon(Icons.star),
    label: Text('Agregar a favoritos'),
  );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          if (_favoritas.isNotEmpty) favoritasComoBotones(),
          campoTexto(),
          SizedBox(height: 10),
          cambioUnidadTemperatura(),
          SizedBox(height: 10),
          if (_cargando) CircularProgressIndicator(),
          if (_ciudad.isNotEmpty && !_cargando) generaRespuesta(),
          if (_ciudad.isEmpty) generaRespuesta(),
        ],
      ),
    );
  }

  Wrap favoritasComoBotones() {
    return Wrap(
      spacing: 8.0,
      children:
          _favoritas.map((e) {
            return InputChip(
              label: Text(e, style: TextStyle(color: Colors.deepOrangeAccent)),
              onPressed: () {
                _controller.text = e;
                obtenerClima(e);
              },
              onDeleted: () {
                setState(() {
                  _favoritas.remove(e);
                });
                _guardarCiudadesFavoritas();
              },
              tooltip: 'Ciudades favoritas',
              backgroundColor: Colors.orange[75],
              shape: CircleBorder(eccentricity: 0.95),
            );
          }).toList(),
    );
  }

  TextField campoTexto() {
    return TextField(
      controller: _controller,
      decoration: InputDecoration(
        labelText: "Ingresa tu ciudad",
        suffixIcon: IconButton(
          onPressed: () => obtenerClima(_controller.text),
          icon: Icon(Icons.search),
        ),
      ),
      onSubmitted: obtenerClima,
    );
  }

  Row cambioUnidadTemperatura() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('°C'),
        Switch(
          value: _usarFahrenheit,
          onChanged: (value) {
            setState(() {
              _usarFahrenheit = value;
            });

            _guardarPreferenciaUnidadTemperatura(value);
            if (_controller.text.isNotEmpty) {
              obtenerClima(_controller.text);
            }
          },
        ),

        Text('°F'),
      ],
    );
  }

  void _cargarCiudadGuardada() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? ciudadGuardada = prefs.getString('ultimaCiudad');
    if (ciudadGuardada != null) {
      _controller.text = ciudadGuardada;
      obtenerClima(ciudadGuardada);
    }
  }

  void _guardarPreferenciaUnidadTemperatura(bool value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('usarFahrenheit', value);
  }

  void _cargarPreferenciaUnidadTemperatura() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _usarFahrenheit = prefs.getBool('usarFahrenheit') ?? false;
    });
  }
}
