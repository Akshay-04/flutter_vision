import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class drawerScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
  borderRadius: BorderRadius.vertical(top: Radius.circular(8.0)),child:Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          DrawerHeader(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/logo.jpeg"),
                fit: BoxFit.cover
              )
            ),
          ),
          ListTile(
            leading: Icon(Icons.home),
            title: Text('Home'),
            onTap: () => {
             
            },
          ),
          ListTile(
            leading: Icon(Icons.exit_to_app),
            title: Text('Exit'),
            onTap: () => {
              SystemNavigator.pop()
             
            },
          )
        ],
      ),
    ));
  }
}