import 'package:otax/core/app/runtimeDatas.dart';
import 'package:flutter/material.dart';

class PluginPage extends StatefulWidget {
  const PluginPage({super.key});

  @override
  State<PluginPage> createState() => _PluginPageState();
}

class _PluginPageState extends State<PluginPage> with TickerProviderStateMixin {
  @override
  initState() {
    super.initState();


  }
























  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: MediaQuery.paddingOf(context),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(
                          Icons.arrow_back_rounded,
                          color: appTheme.textMainColor,
                          size: 28,
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.only(left: 10, right: 20),
                        child: Text(
                          "Manage Providers [Beta]",
                          style: TextStyle(
                            fontFamily: "Rubik",
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () {},
                    icon: Icon(
                      Icons.science_sharp,
                      size: 25,
                      color: appTheme.textMainColor,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(child: Center(child: Text("Should arrive soon!"))),



































          ],
        ),
      ),
    );
  }






















































































}
