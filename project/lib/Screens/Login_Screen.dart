import 'package:flutter/material.dart';

class MyWidget extends StatelessWidget {
  const MyWidget({super.key});

  facebooklogin(){
    print("FaceBook Login Called!");
  }

  @override
  Widget build(BuildContext context) {
    return  Scaffold(
      appBar: AppBar(
        title: const Text ("Login Screen"),
      ),
      body: Center(child: 
      ElevatedButton(child: 
      const Text('Login With Facebook'),
      onPressed: facebooklogin,
      ),),
    );
  }
}