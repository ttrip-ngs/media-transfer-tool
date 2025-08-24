import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/design/professional_theme.dart';
import 'screens/professional_screen.dart';
import 'providers/media_provider.dart';
import 'providers/folder_provider.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => MediaProvider()),
        ChangeNotifierProvider(create: (_) => FolderProvider()),
      ],
      child: const MediaTransferApp(),
    ),
  );
}

class MediaTransferApp extends StatelessWidget {
  const MediaTransferApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Media Transfer Pro',
      debugShowCheckedModeBanner: false,
      theme: ProTheme.theme(),
      home: const ProfessionalScreen(),
    );
  }
}