import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'package:provider/provider.dart';
import 'data/storage_service.dart';
import 'providers/auth_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/benefit_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/terms_agreement_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/home_screen.dart';
import 'screens/calendar_screen.dart';
import 'screens/custom_search_screen.dart';
import 'screens/my_page_screen.dart';
import 'core/constants/app_colors.dart';
import 'core/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // table_calendar 의 ko_KR 로케일 누락으로 인한 LocaleDataException 방지
  await initializeDateFormatting('ko_KR', null);

  // 환경 변수 로드
  await dotenv.load(fileName: ".env");

  // 카카오 SDK 초기화
  KakaoSdk.init(
    nativeAppKey: dotenv.env['KAKAO_NATIVE_APP_KEY'] ?? '',
    javaScriptAppKey: dotenv.env['KAKAO_JAVASCRIPT_APP_KEY'] ?? '',
  );

  // SharedPreferences 초기화 (찜 목록 / 달력 이벤트 로드)
  await StorageService.instance.init();

  // 알림 서비스 초기화
  final notificationService = NotificationService();
  await notificationService.init();

  final authProvider = AuthProvider();
  await authProvider.init();

  final settingsProvider = SettingsProvider.instance;
  await settingsProvider.init();

  final benefitProvider = BenefitProvider();

  runApp(AlryeodeurimApp(
    authProvider: authProvider,
    settingsProvider: settingsProvider,
    benefitProvider: benefitProvider,
  ));
}

class AlryeodeurimApp extends StatelessWidget {
  final AuthProvider authProvider;
  final SettingsProvider settingsProvider;
  final BenefitProvider benefitProvider;

  const AlryeodeurimApp({
    super.key,
    required this.authProvider,
    required this.settingsProvider,
    required this.benefitProvider,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
        ChangeNotifierProvider<SettingsProvider>.value(value: settingsProvider),
        ChangeNotifierProvider<BenefitProvider>.value(value: benefitProvider),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settings, _) {
          return MaterialApp(
            title: '알려드림',
            debugShowCheckedModeBanner: false,
            themeMode: settings.themeMode, // 시스템 설정 / 라이트 / 다크 실시간 대응
            theme: ThemeData(
              useMaterial3: true,
              colorScheme: ColorScheme.fromSeed(
                seedColor: AppColors.accentPurple,
                brightness: Brightness.light,
              ),
              // 카카오톡/토스/디스코드 스타일: 구분선을 없애고 여백으로 영역을 나눔
              dividerColor: Colors.transparent,
              cardTheme: const CardThemeData(
                elevation: 0,
                surfaceTintColor: Colors.transparent,
              ),
            ),
            darkTheme: ThemeData(
              useMaterial3: true,
              colorScheme: ColorScheme.fromSeed(
                seedColor: AppColors.accentPurple,
                brightness: Brightness.dark,
              ),
              dividerColor: Colors.transparent,
              cardTheme: const CardThemeData(
                elevation: 0,
                surfaceTintColor: Colors.transparent,
              ),
            ),
            // 전역 글자 크기 배율(1.0x~1.5x)을 앱 전체 텍스트에 실시간 반영
            builder: (context, child) {
              final mediaQuery = MediaQuery.of(context);
              return MediaQuery(
                data: mediaQuery.copyWith(
                  textScaler: TextScaler.linear(settings.textScale),
                ),
                child: child!,
              );
            },
            home: const AuthGate(),
          );
        },
      ),
    );
  }
}

/// AuthProvider.status 값에 따라 로그인 -> 약관동의 -> 회원가입 -> 홈 을 자동 분기하는 게이트 위젯.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final status = context.watch<AuthProvider>().status;

    switch (status) {
      case AuthStatus.loading:
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      case AuthStatus.loggedOut:
        return const LoginScreen();
      case AuthStatus.needsTermsAgreement:
        return const TermsAgreementScreen();
      case AuthStatus.needsSignUp:
        return const SignUpScreen();
      case AuthStatus.loggedIn:
        return const RootNavigation();
    }
  }
}

class RootNavigation extends StatefulWidget {
  const RootNavigation({super.key});

  @override
  State<RootNavigation> createState() => _RootNavigationState();
}

class _RootNavigationState extends State<RootNavigation> {
  int _currentIndex = 0;

  late final List<Widget> _tabs = [
    const HomeScreen(),
    const CalendarScreen(),
    const CustomSearchScreen(),
    MyPageScreen(onGoHome: () {
      if (mounted) setState(() => _currentIndex = 0);
    }),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _tabs,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) =>
            setState(() => _currentIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: '홈',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: '혜택 달력',
          ),
          NavigationDestination(
            icon: Icon(Icons.search_outlined),
            selectedIcon: Icon(Icons.search),
            label: '맞춤검색',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: '마이페이지',
          ),
        ],
      ),
    );
  }
}