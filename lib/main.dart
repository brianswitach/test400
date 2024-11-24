import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
void main() {
  runApp(const MyApp());
}
class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'API InfoControl',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const LoginScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  _LoginScreenState createState() => _LoginScreenState();
}
class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController =
      TextEditingController(text: "api.mobile");
  final TextEditingController _passwordController =
      TextEditingController(text: "ApiInfoC24");
  String bearerToken = "";
  bool isLoginSuccessful = false;
  bool isLoading = false;
  // URLs de la API
  static const String baseUrl = "https://www.infocontrol.tech/web/api";
  static const String loginUrl = "$baseUrl/web/workers/login";
  static const String empresasUrl = "$baseUrl/mobile/empleados/listar";
  // Cookie de sesión
  static const String sessionCookie =
      'ci_session_infocontrolweb1=p3qcojig9a9c1qhec5st0k90uvj4tdrg; cookie_sistema=3588d89653839cdb1fbaf485dd3a401c';
  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
  Future<void> login(BuildContext context) async {
    if (!mounted) return;
    setState(() {
      isLoading = true;
    });
    try {
      String username = _usernameController.text.trim();
      String password = _passwordController.text.trim();
      if (username.isEmpty || password.isEmpty) {
        await _showAlertDialog(
            context, "Campos Vacíos", "Por favor, completa todos los campos.");
        return;
      }
      // Preparar el cuerpo de la solicitud
      Map<String, String> requestBody = {
        'username': username,
        'password': password,
      };
      String jsonBody = jsonEncode(requestBody);
      String basicAuth =
          'Basic ' + base64Encode(utf8.encode('$username:$password'));
      print("Iniciando solicitud de login...");
      print("URL: $loginUrl");
      print("Headers de autenticación: $basicAuth");
      final loginResponse = await http.post(
        Uri.parse(loginUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': basicAuth,
          'Cookie': sessionCookie,
          'Host': 'www.infocontrol.tech',
          'Accept': '*/*',
          'Accept-Encoding': 'gzip, deflate, br',
          'Connection': 'keep-alive',
          'Cache-Control': 'no-cache',
        },
        body: jsonBody,
      );
      print("Código de estado de login: ${loginResponse.statusCode}");
      print("Respuesta de login: ${loginResponse.body}");
      print("Headers de respuesta: ${loginResponse.headers}");
      if (loginResponse.statusCode == 200) {
        final loginData = jsonDecode(loginResponse.body);
        if (loginData['data'] != null && loginData['data']['Bearer'] != null) {
          setState(() {
            bearerToken = loginData['data']['Bearer'];
            isLoginSuccessful = true;
          });
          await _showAlertDialog(context, "Login Exitoso",
              "Autenticación exitosa. Obteniendo lista de empresas...");
          await fetchEmpresasList(context);
        } else {
          throw Exception('Estructura de respuesta inesperada');
        }
      } else {
        throw Exception(
            'Error ${loginResponse.statusCode}: ${loginResponse.body}');
      }
    } catch (e) {
      print("Error durante el login: $e");
      await _showAlertDialog(
          context, "Error", "Ocurrió un error durante el login: $e");
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }
  Future<void> fetchEmpresasList(BuildContext context) async {
    if (!mounted) return;
    setState(() {
      isLoading = true;
    });
    try {
      print("Iniciando solicitud de lista de empresas...");
      print("URL: $empresasUrl");
      print("Token Bearer: $bearerToken");
      // Crear el body de la solicitud
      Map<String, dynamic> requestBody = {
        "fecha": DateTime.now().toIso8601String(),
        "tipo": "lista"
      };
      final empresasResponse = await http.get(
        Uri.parse(empresasUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $bearerToken',
          'Cookie': sessionCookie,
          'Host': 'www.infocontrol.tech',
          'Accept': '*/*',
          'Accept-Encoding': 'gzip, deflate, br',
          'Connection': 'keep-alive',
          'Cache-Control': 'no-cache',
        },
      );
      print("Código de estado de empresas: ${empresasResponse.statusCode}");
      print("Headers de respuesta: ${empresasResponse.headers}");
      print("Cuerpo de respuesta: ${empresasResponse.body}");
      if (empresasResponse.statusCode == 200) {
        final empresasData = jsonDecode(empresasResponse.body);
        await _showAlertDialog(context, "Lista de Empresas",
            "Datos obtenidos exitosamente:\n${jsonEncode(empresasData)}");
      } else {
        throw Exception(
            'Error ${empresasResponse.statusCode}: ${empresasResponse.body}');
      }
    } catch (e) {
      print("Error al obtener lista de empresas: $e");
      await _showAlertDialog(
          context, "Error", "Error al obtener lista de empresas: $e");
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }
  Future<void> _showAlertDialog(
      BuildContext context, String title, String message) async {
    if (!mounted) return;
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: SingleChildScrollView(
            child: Text(message),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("OK"),
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
        title: const Text("Login API InfoControl"),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _usernameController,
                  decoration: const InputDecoration(
                    labelText: "Usuario",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                  enabled: !isLoading,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    labelText: "Contraseña",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock),
                  ),
                  obscureText: true,
                  enabled: !isLoading,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: isLoading ? null : () => login(context),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(isLoading ? "Procesando..." : "Ingresar"),
                ),
                if (isLoginSuccessful) ...[
                  const SizedBox(height: 16),
                  Text(
                    "Estado: Autenticado",
                    style: TextStyle(
                      color: Colors.green[700],
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
          if (isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}