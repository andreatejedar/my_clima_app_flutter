import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

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
  //  bool _usarFahrenheit = false;

  @override
  initState() {
    super.initState();
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

    // final apiKey = "3c5c7cd19d1e7b84c8e3bbf91d3174c5";
    final urlClima =
        'https://api.openweathermap.org/data/2.5/weather?q=$ciudad&appid=$apiKey&units=metric&lang=es';

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
          Text('$_temperatura °C', style: estiloTemperatura),
        if (_description.isNotEmpty)
          Text(_description, style: estiloDescripcion),
        if (_iconoUrl.isNotEmpty)
          Image.network(_iconoUrl, height: 100, color: Colors.blueAccent),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          TextField(
            controller: _controller,
            decoration: InputDecoration(
              labelText: "Ingresa tu ciudad",
              suffixIcon: IconButton(
                onPressed: () => obtenerClima(_controller.text),
                icon: Icon(Icons.search),
              ),
            ),
            onSubmitted: obtenerClima,
          ),
          SizedBox(height: 20),
          if (_cargando) CircularProgressIndicator(),
          if (_ciudad.isNotEmpty && !_cargando) generaRespuesta(),
          if (_ciudad.isEmpty) generaRespuesta(),
        ],
      ),
    );
  }
}
