import 'dart:ffi';

import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Easytrip balance inquiry',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
        // This makes the visual density adapt to the platform that you run
        // the app on. For desktop platforms, the controls will be smaller and
        // closer together (more dense) than on mobile platforms.
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(title: 'Easytrip balance inquiry'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;
  String _accountNumber = "";
  double _balance = 0.00;
  bool _balanceFetchSuccess = false;
  bool _isLoading = false;
  bool _showErrorMessage = false;
  var textController = new TextEditingController();

  Future<void> fetchBalance() async {
    setState(() {
      _balanceFetchSuccess = false;
      _isLoading = true;
      _showErrorMessage = false;
    });

    final response = await http.get(
        'https://easytrip-frontend-api.topup.ninja/balance/$_accountNumber');

    if (response.statusCode == 200) {
      // If the server did return a 200 OK response,
      // then parse the JSON.
      var result = jsonDecode(response.body);
      var balanse = result["balance"].toString();
      setState(() {
        _balanceFetchSuccess = true;
        _isLoading = false;
        _balance = double.parse(balanse);
      });

      //saveAccountNumberToStorage();

      SharedPreferences prefs = await SharedPreferences.getInstance();
      prefs.setString('accountnumber', _accountNumber);
    } else {
      setState(() {
        _showErrorMessage = true;
        _isLoading = false;
      });
    }
  }

  Widget _RenderBalanceResult() {
    return Column(
      children: <Widget>[
        Text(
          'Your current balance is',
          style: Theme.of(context).textTheme.headline5,
        ),
        Text(
          '$_balance',
          style: Theme.of(context).textTheme.headline3,
        ),
      ],
    );
  }

  Widget renderErrorMessage() {
    return Container(
      child: Text("Please make sure your account number is the correct",
          style: TextStyle(color: Colors.red)),
      padding: EdgeInsets.all(10),
    );
  }

  loadStoredAccountNumber() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var storedAccountNumber = prefs.getString("accountnumber");

    if (storedAccountNumber != null) {
      setState(() {
        _accountNumber = storedAccountNumber;
        textController.text = _accountNumber;
      });
      await fetchBalance();
    }
  }

  Widget renderAccountNumberInput() {
    return Container(
      margin: EdgeInsets.only(bottom: 10),
      child: TextField(
        textAlign: TextAlign.center,
        controller: textController,
        maxLength: 12,
        enabled: !_isLoading,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          border: new OutlineInputBorder(
            borderRadius: const BorderRadius.all(
              const Radius.circular(10.0),
            ),
          ),
          hintText: 'Enter EasyTrip account number',
          hintStyle: Theme.of(context)
              .textTheme
              .headline6
              .copyWith(color: Theme.of(context).textTheme.headline3.color),
          counterText: '',
        ),

        style: Theme.of(context).textTheme.headline3,
        // style: TextStyle(
        //   fontSize: 40.0,
        //   height: 2.0,
        //   color: Colors.black,
        // ),

        onChanged: (value) async {
          if (value.length == 12) {
            setState(() {
              _accountNumber = value;
            });
            await fetchBalance();
          }
        },
      ),
    );
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    loadStoredAccountNumber();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Container(
          margin: EdgeInsets.all(30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              renderAccountNumberInput(),
              _balanceFetchSuccess && !_isLoading
                  ? _RenderBalanceResult()
                  : SizedBox.shrink(),
              _isLoading ? CircularProgressIndicator() : SizedBox.shrink(),
              _showErrorMessage ? renderErrorMessage() : SizedBox.shrink(),
            ],
          ),
        ),
      ),
      floatingActionButton: _accountNumber.length == 12 && _balanceFetchSuccess
          ? FloatingActionButton(
              onPressed: fetchBalance,
              tooltip: 'Increment',
              child: Icon(Icons.refresh),
            )
          : SizedBox
              .shrink(), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
