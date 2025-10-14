import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/providers/application_provider.dart';
import 'core/providers/auth_provider.dart';
import 'core/providers/project_provider.dart';
import 'core/providers/showcase_provider.dart';
import 'core/providers/skill_test_provider.dart';
import 'core/providers/theme_provider.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/screens/home_screen.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),

        ChangeNotifierProxyProvider<AuthProvider, ApplicationProvider>(
          create: (context) => ApplicationProvider(),
          update: (context, auth, previousProvider) {
            previousProvider?.updateToken(auth.token);
            return previousProvider ?? ApplicationProvider();
          },
        ),

        // PROJECT PROVIDER İÇİN GÜNCELLEME
        ChangeNotifierProxyProvider<AuthProvider, ProjectProvider>(
          create: (context) => ProjectProvider(),
          update: (context, auth, previousProvider) {
            previousProvider?.updateToken(auth.token);
            return previousProvider ?? ProjectProvider();
          },
        ),

        ChangeNotifierProxyProvider<AuthProvider, SkillTestProvider>(
          create: (context) => SkillTestProvider(),
          update: (context, auth, previous) {
            previous?.updateToken(auth.token);
            return previous ?? SkillTestProvider();
          },
        ),

        ChangeNotifierProxyProvider<AuthProvider, ShowcaseProvider>(
          create: (context) => ShowcaseProvider(),
          update: (context, auth, previousProvider) {
            // AuthProvider'dan gelen token'ı ShowcaseProvider'a iletiyoruz.
            previousProvider?.updateToken(auth.token);
            return previousProvider ?? ShowcaseProvider();
          },
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // MyApp widget'ı içindeki build metodu
  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'TasarımcıBulutu',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.themeMode,

          // --- YENİ EKLENEN ALANLAR ---
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('tr', 'TR'), // Türkçe desteği
            Locale('en', 'US'), // İngilizce (varsayılan) desteği
          ],
          // --- BİTTİ ---

          debugShowCheckedModeBanner: false,
          home: const AuthWrapper(),
        );
      },
    );
  }
}

// Adım 3: Bu yeni widget, Provider'ı dinleyip doğru ekranı seçiyor.
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // Burada Consumer kullanarak AuthProvider'ı dinliyoruz.
    // Bu BuildContext, MaterialApp'in içinde olduğu için Provider'ı bulabilir.
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        // Eğer AuthProvider hala token kontrolü yapıyorsa, SplashScreen'i göster
        if (auth.isLoading) {
          return const SplashScreen();
        }

        // Kontrol bittiyse ve kullanıcı giriş yapmışsa HomeScreen'i göster
        if (auth.isLoggedIn) {
          return const HomeScreen();
        }
        // Kontrol bittiyse ve giriş yapmamışsa LoginScreen'i göster
        else {
          return const LoginScreen();
        }
      },
    );
  }
}