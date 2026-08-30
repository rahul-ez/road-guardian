import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class Home extends StatefulWidget {
	const Home({super.key});

	@override
	State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
	@override
	Widget build(BuildContext context) {
		return Scaffold(
			body: SafeArea(
				child: Padding(
					padding: const EdgeInsets.all(24.0),
					child: Column(
						crossAxisAlignment: CrossAxisAlignment.stretch,
						children: [
							const SizedBox(height: 40),
							Icon(
								Icons.remove_road_rounded,
								size: 80,
								color: Theme.of(context).primaryColor,
							),
							const SizedBox(height: 24),
							Text(
								"Road Guardian",
								textAlign: TextAlign.center,
								style: Theme.of(context).textTheme.headlineLarge?.copyWith(
									fontWeight: FontWeight.bold,
									color: Colors.white,
								),
							),
							const SizedBox(height: 8),
							Text(
								"Smart Pothole Detection",
								textAlign: TextAlign.center,
								style: Theme.of(context).textTheme.bodyLarge?.copyWith(
									color: Colors.grey,
								),
							),
							const SizedBox(height: 60),
							
							Expanded(
								child: GridView.count(
									crossAxisCount: 1,
									mainAxisSpacing: 16,
									childAspectRatio: 2.5,
									children: [
										_MenuCard(
											title: "Manual Detection",
											subtitle: "Upload or capture a single image",
											icon: Icons.upload_file_rounded,
											onTap: () => context.go('/manual'),
										),
										_MenuCard(
											title: "Live Feed",
											subtitle: "Real-time detection using camera",
											icon: Icons.camera_alt_rounded,
											onTap: () => context.go('/automatic'),
										),
									],
								),
							),
						],
					),
				),
			),
		);
	}
}

class _MenuCard extends StatelessWidget {
	final String title;
	final String subtitle;
	final IconData icon;
	final VoidCallback onTap;

	const _MenuCard({
		required this.title,
		required this.subtitle,
		required this.icon,
		required this.onTap,
	});

	@override
	Widget build(BuildContext context) {
		return Card(
			clipBehavior: Clip.antiAlias,
			child: InkWell(
				onTap: onTap,
				child: Padding(
					padding: const EdgeInsets.all(20.0),
					child: Row(
						children: [
							Container(
								padding: const EdgeInsets.all(12),
								decoration: BoxDecoration(
									color: Theme.of(context).primaryColor.withOpacity(0.1),
									borderRadius: BorderRadius.circular(12),
								),
								child: Icon(
									icon,
									size: 32,
									color: Theme.of(context).primaryColor,
								),
							),
							const SizedBox(width: 20),
							Expanded(
								child: Column(
									crossAxisAlignment: CrossAxisAlignment.start,
									mainAxisAlignment: MainAxisAlignment.center,
									children: [
										Text(
											title,
											style: Theme.of(context).textTheme.titleMedium?.copyWith(
												fontWeight: FontWeight.bold,
												fontSize: 18,
											),
										),
										const SizedBox(height: 4),
										Text(
											subtitle,
											style: Theme.of(context).textTheme.bodyMedium?.copyWith(
												color: Colors.grey,
											),
										),
									],
								),
							),
							const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey),
						],
					),
				),
			),
		);
	}
}
