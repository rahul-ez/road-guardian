import 'package:flutter/material.dart';

class HoleYea extends StatefulWidget {
	const HoleYea({super.key});

	@override
	State<StatefulWidget> createState() => _HoleYeaState();
}

class _HoleYeaState extends State<HoleYea> {
	@override
	  Widget build(BuildContext context) {
		return MaterialApp( 
			title: "Road Guardian",
			home: Scaffold( 
				appBar: AppBar(title: Text("Road Guardian"),),
				body: Center(child: Column(
					crossAxisAlignment: CrossAxisAlignment.center,
					mainAxisAlignment: MainAxisAlignment.center,
					mainAxisSize: MainAxisSize.max,
					children: [
						TextButton(
							onPressed: () {
								// Go to manual detection mode
							}, 
							child: Text("Manual Detection")
						),

						TextButton(
							onPressed: () {
							// go to automatic
							},
							child: Text("Automatic Detection"),
						)
					],
				),)
			),
		);
	  }
}
