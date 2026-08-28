import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/settings_provider.dart';
import 'legal_info_screen.dart';
import 'faq_screen.dart';
import 'inquiry_screen.dart';
import 'notice_board_screen.dart';
import '../../../core/constants/app_colors.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('설정')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SectionTitle('화면 테마'),
          _ThemeModeSelector(
            currentMode: settings.themeMode,
            onChanged: (mode) => settings.setThemeMode(mode),
          ),
          const SizedBox(height: 28),

          _SectionTitle('글자 크기'),
          _TextScaleSlider(
            currentScale: settings.textScale,
            onChanged: (scale) => settings.setTextScale(scale),
          ),
          const SizedBox(height: 28),

          _SectionTitle('법적 정보'),
          _SettingsTile(
            icon: Icons.description_outlined,
            title: '이용약관 및 개인정보 처리방침',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const LegalInfoScreen()),
            ),
          ),
          _SettingsTile(
            icon: Icons.copyright_outlined,
            title: '오픈소스 라이선스',
            subtitle: 'MIT, BSD, OFL 등 사용된 오픈소스 목록',
            onTap: () => showLicensePage(
              context: context,
              applicationName: '알려드림',
              applicationVersion: '1.0.0',
              applicationLegalese: '© 2026 알려드림. 사용된 모든 오픈소스는 각 라이선스를 준수합니다.',
            ),
          ),
          _SettingsTile(
            icon: Icons.policy_outlined,
            title: '공공데이터 활용 안내 및 저작권',
            subtitle: '데이터 출처 및 면책 조항 (필독)',
            onTap: () => _showDataDisclaimer(context),
          ),
          const SizedBox(height: 28),

          _SectionTitle('고객 지원'),
          _SettingsTile(
            icon: Icons.help_outline,
            title: 'FAQ',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const FaqScreen()),
            ),
          ),
          _SettingsTile(
            icon: Icons.support_agent_outlined,
            title: '1:1 문의하기',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const InquiryScreen()),
            ),
          ),
          _SettingsTile(
            icon: Icons.campaign_outlined,
            title: '공지사항',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const NoticeBoardScreen()),
            ),
          ),
        ],
      ),
    );
  }

  void _showDataDisclaimer(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('공공데이터 활용 안내'),
        content: const SingleChildScrollView(
          child: Text(
            '본 앱("알려드림")은 공공데이터포털(data.go.kr), 복지로, 한국장학재단 등에서 제공하는 오픈 API(공공데이터)를 가공하여 청년 정책 정보를 제공하는 개인 개발 애플리케이션입니다.\n\n'
            '본 앱은 어떠한 정부 기관, 지자체, 혹은 공공기관을 대표하거나 공식적인 관계를 맺고 있지 않으며, 정부 기관의 공식 앱이 아닙니다.\n\n'
            '본 앱에서 제공하는 정보의 정확성이나 최신성에 대해서는 보증하지 않으며, 실제 혜택 신청 및 정확한 정보 확인은 각 정책의 원본(공식) 웹사이트를 통해 진행하셔야 합니다.\n\n'
            '저작권 안내:\n'
            '- 공공데이터에 대한 저작권 및 책임은 각 공공데이터 제공 기관에 있습니다.\n'
            '- 앱 내 UI/UX 디자인 및 소스코드에 대한 저작권은 개발자에게 있습니다.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}

class _ThemeModeSelector extends StatelessWidget {
  final ThemeMode currentMode;
  final ValueChanged<ThemeMode> onChanged;

  const _ThemeModeSelector({
    required this.currentMode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        children: [
          _themeOption(context, ThemeMode.system, '시스템 설정', Icons.settings_suggest_outlined),
          const Divider(height: 1),
          _themeOption(context, ThemeMode.light, '라이트 모드', Icons.light_mode_outlined),
          const Divider(height: 1),
          _themeOption(context, ThemeMode.dark, '다크 모드', Icons.dark_mode_outlined),
        ],
      ),
    );
  }

  Widget _themeOption(
    BuildContext context,
    ThemeMode mode,
    String label,
    IconData icon,
  ) {
    final isSelected = currentMode == mode;
    return RadioListTile<ThemeMode>(
      value: mode,
      // ignore: deprecated_member_use
      groupValue: currentMode,
      // ignore: deprecated_member_use
      onChanged: (value) {
        if (value != null) onChanged(value);
      },
      activeColor: AppColors.accentPurple,
      title: Row(
        children: [
          Icon(icon, size: 20, color: isSelected ? AppColors.accentPurple : Colors.grey),
          const SizedBox(width: 10),
          Text(label),
        ],
      ),
    );
  }
}

class _TextScaleSlider extends StatelessWidget {
  final double currentScale;
  final ValueChanged<double> onChanged;

  const _TextScaleSlider({
    required this.currentScale,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Theme.of(context).dividerColor),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('가나다 Aa 미리보기', style: TextStyle(fontSize: 15)),
                Text(
                  '${currentScale.toStringAsFixed(1)}x',
                  style: const TextStyle(
                    color: AppColors.accentPurple,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Transform.scale(
              scale: currentScale,
              alignment: Alignment.centerLeft,
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text('청년 정책 혜택을 한눈에 확인하세요'),
              ),
            ),
            Slider(
              value: currentScale,
              min: 1.0,
              max: 1.5,
              divisions: 5, // 0.1 단위
              activeColor: AppColors.accentPurple,
              label: '${currentScale.toStringAsFixed(1)}x',
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Theme.of(context).dividerColor),
      ),
      child: ListTile(
        leading: Icon(icon, color: AppColors.accentPurple),
        title: Text(title),
        subtitle: subtitle != null ? Text(subtitle!) : null,
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}