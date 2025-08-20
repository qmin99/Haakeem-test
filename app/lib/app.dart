import 'package:flutter/material.dart' hide ConnectionState;
import 'package:provider/provider.dart';
import 'package:livekit_components/livekit_components.dart' as components;

import 'constants/app_constants.dart';
import 'providers/chat_provider.dart';
import 'providers/voice_provider.dart';
import 'providers/file_provider.dart';
import 'controllers/app_ctrl.dart';
import 'screens/main_screen.dart';

class VoiceAssistantApp extends StatelessWidget {
  const VoiceAssistantApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppCtrl()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => VoiceProvider()),
        ChangeNotifierProvider(create: (_) => FileProvider()),
      ],
      child: Consumer<AppCtrl>(
        builder: (context, appCtrl, child) {
          if (appCtrl.connectionState == ConnectionState.connected) {
            return ChangeNotifierProvider<components.RoomContext>.value(
              value: appCtrl.roomContext,
              child: MaterialApp(
                title: AppStrings.appName,
                debugShowCheckedModeBanner: false,
                theme: _buildTheme(),
                home: const MainScreen(),
              ),
            );
          }
          
          return MaterialApp(
            title: AppStrings.appName,
            debugShowCheckedModeBanner: false,
            theme: _buildTheme(),
            home: const MainScreen(),
          );
        },
      ),
    );
  }

  ThemeData _buildTheme() {
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Inter',
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primaryGreen,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: AppColors.lightBackground,
      cardColor: AppColors.cardBackground,
      dividerColor: AppColors.borderColor,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.cardBackground,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: false,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.lightBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.borderRadiusLarge),
          borderSide: const BorderSide(color: AppColors.borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.borderRadiusLarge),
          borderSide: const BorderSide(color: AppColors.borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.borderRadiusLarge),
          borderSide: const BorderSide(color: AppColors.primaryGreen, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSizes.paddingLarge,
          vertical: AppSizes.paddingMedium,
        ),
      ),
    );
  }
}