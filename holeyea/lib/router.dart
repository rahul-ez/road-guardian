import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:holeyea/ui/feed.dart';
import 'package:holeyea/ui/home.dart';
import 'package:holeyea/ui/manual.dart';
import 'package:holeyea/viewmodels/feed_view_model.dart';
import 'package:provider/provider.dart';

final router = GoRouter(
	routes: [
		GoRoute(
			path: '/',
			builder: (_, __) => Home()
		),

		GoRoute(
			path: '/manual',
			builder: (_, __) => const ManualDetection()
		),

		GoRoute(
			path: '/automatic',
			builder: (c, _) => Feed(vm: FeedViewModel(c.read()),)
		)
	]
);
