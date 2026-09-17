import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/safety_level.dart';
import '../../core/models/user_role.dart';
import '../../core/widgets/freshness_bar.dart';
import '../advisory/advisory_controller.dart';
import '../alarm/alarm_controller.dart';
import '../auth/auth_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/action_card.dart';
import '../../core/widgets/metric_tile.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/status_hero.dart';
import '../../core/widgets/voice_button.dart';
import '../voyage/voyage_controller.dart';

/// The home screen, and the only screen most trips will ever need.
///
/// Reading order is fixed and shallow: can I go out, what is the sea doing, how
/// close is the border, ask a question. Nothing is hidden behind a menu.
class SafetyScreen extends ConsumerWidget {
  const SafetyScreen({super.key, required this.onAsk, required this.onOpenMap});

  final VoidCallback onAsk;
  final VoidCallback onOpenMap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conditions = ref.watch(seaConditionsProvider);
    final boundary = ref.watch(boundaryStatusProvider);
    final voyage = ref.watch(voyageProvider);
    final advisory = ref.watch(advisoryProvider);
    final alarm = ref.watch(alarmProvider);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: AppSizes.gutter,
        title: const _Wordmark(),
        actions: const [
          _ProfileChip(),
          SizedBox(width: 8),
          _LanguageChip(),
          SizedBox(width: AppSizes.gutter),
        ],
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSizes.gutter,
            8,
            AppSizes.gutter,
            32,
          ),
          children: [
            StatusHero(
              level: conditions.level,
              summary: conditions.summary,
              footnote: 'Updated ${conditions.ageLabel.toLowerCase()}',
            ),
            const SizedBox(height: 26),

            const SectionHeader(title: 'Sea right now', titleTa: 'கடல் நிலை'),
            Row(
              children: [
                Expanded(
                  child: MetricTile(
                    icon: Icons.waves_rounded,
                    value: conditions.waveHeightM.toStringAsFixed(1),
                    unit: 'm',
                    caption: 'Waves',
                    captionTa: 'அலைகள்',
                    tint: AppColors.horizon,
                  ),
                ),
                const SizedBox(width: AppSizes.gap),
                Expanded(
                  child: MetricTile(
                    icon: Icons.air_rounded,
                    value: conditions.windSpeedKmh.toStringAsFixed(0),
                    unit: 'km/h',
                    caption: 'Wind',
                    captionTa: 'காற்று',
                    tint: AppColors.horizon,
                  ),
                ),
                const SizedBox(width: AppSizes.gap),
                Expanded(
                  child: MetricTile(
                    icon: Icons.visibility_rounded,
                    value: conditions.visibilityKm.toStringAsFixed(0),
                    unit: 'km',
                    caption: 'Visibility',
                    captionTa: 'தெளிவு',
                    tint: AppColors.horizon,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),

            const SectionHeader(
              title: 'Offline data',
              titleTa: 'சேமித்த தரவு',
            ),
            FreshnessBar(pack: advisory.value),
            const SizedBox(height: AppSizes.gap),
            ActionCard(
              icon: advisory.isLoading
                  ? Icons.hourglass_top_rounded
                  : Icons.download_rounded,
              accent: AppColors.horizon,
              title: advisory.isLoading
                  ? 'Downloading…'
                  : 'Download for offline use',
              subtitle: ref.read(advisoryProvider.notifier).lastError ??
                  'Get boundaries, fishing zones and forecast',
              trailing: advisory.isLoading
                  ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              )
                  : null,
              onTap: advisory.isLoading
                  ? null
                  : () => ref
                  .read(advisoryProvider.notifier)
                  .download(voyage.position),
            ),
            const SizedBox(height: 28),

            const SectionHeader(title: 'Boundary', titleTa: 'எல்லை'),
            ActionCard(
              icon: alarm.level.isActive
                  ? alarm.level.icon
                  : (boundary.level == SafetyLevel.safe
                  ? Icons.shield_outlined
                  : Icons.report_problem_rounded),
              accent: alarm.level.isActive
                  ? alarm.level.color
                  : boundary.level.color,
              title: boundary.headline,
              subtitle: boundary.isApproaching
                  ? 'Heading toward ${boundary.name}'
                  : '${boundary.name} — not approaching',
              onTap: onOpenMap,
            ),
            const SizedBox(height: AppSizes.gap),
            ActionCard(
              icon: voyage.underway
                  ? Icons.stop_circle_outlined
                  : Icons.sailing_rounded,
              accent: voyage.underway ? AppColors.danger : AppColors.safe,
              title: voyage.underway ? 'End trip' : 'Start trip',
              subtitle: voyage.underway
                  ? 'Tracking at ${voyage.speedKnots.toStringAsFixed(1)} knots'
                  : 'Begin tracking and boundary alerts',
              trailing: Switch(
                value: voyage.underway,
                onChanged: (_) =>
                    ref.read(voyageProvider.notifier).toggleVoyage(),
              ),
              onTap: () => ref.read(voyageProvider.notifier).toggleVoyage(),
            ),
            if (voyage.permissionDenied) ...[
              const SizedBox(height: AppSizes.gap),
              const _PermissionWarning(),
            ],
            const SizedBox(height: 28),

            VoiceButton(onTap: onAsk),
          ],
        ),
      ),
    );
  }
}

class _Wordmark extends StatelessWidget {
  const _Wordmark();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: AppColors.deepSea,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.waves_rounded, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text('ORCA', style: Theme.of(context).textTheme.titleLarge),
        ),
      ],
    );
  }
}

/// One of the 23 languages offered in the language picker.
///
/// [english] is used as the stable identifier / label in the menu,
/// [native] is what's shown on the chip once selected.
class _IndianLanguage {
  const _IndianLanguage(this.english, this.native);

  final String english;
  final String native;
}

/// The 22 languages of the Eighth Schedule of the Indian Constitution,
/// plus English, for 23 total options.
const List<_IndianLanguage> _kIndianLanguages = [
  _IndianLanguage('English', 'English'),
  _IndianLanguage('Assamese', 'অসমীয়া'),
  _IndianLanguage('Bengali', 'বাংলা'),
  _IndianLanguage('Bodo', 'बड़ो'),
  _IndianLanguage('Dogri', 'डोगरी'),
  _IndianLanguage('Gujarati', 'ગુજરાતી'),
  _IndianLanguage('Hindi', 'हिन्दी'),
  _IndianLanguage('Kannada', 'ಕನ್ನಡ'),
  _IndianLanguage('Kashmiri', 'کٲشُر'),
  _IndianLanguage('Konkani', 'कोंकणी'),
  _IndianLanguage('Maithili', 'मैथिली'),
  _IndianLanguage('Malayalam', 'മലയാളം'),
  _IndianLanguage('Manipuri (Meitei)', 'মৈতৈলোন্'),
  _IndianLanguage('Marathi', 'मराठी'),
  _IndianLanguage('Nepali', 'नेपाली'),
  _IndianLanguage('Odia', 'ଓଡ଼ିଆ'),
  _IndianLanguage('Punjabi', 'ਪੰਜਾਬੀ'),
  _IndianLanguage('Sanskrit', 'संस्कृतम्'),
  _IndianLanguage('Santali', 'ᱥᱟᱱᱛᱟᱲᱤ'),
  _IndianLanguage('Sindhi', 'سنڌي'),
  _IndianLanguage('Tamil', 'தமிழ்'),
  _IndianLanguage('Telugu', 'తెలుగు'),
  _IndianLanguage('Urdu', 'اردو'),
];

/// Language switcher chip.
///
/// Selecting a language only updates what's shown on this chip — it is
/// intentionally decoupled from the rest of the app for now.
class _LanguageChip extends StatefulWidget {
  const _LanguageChip();

  @override
  State<_LanguageChip> createState() => _LanguageChipState();
}

class _LanguageChipState extends State<_LanguageChip> {
  // Defaults to Tamil to match the chip's previous hardcoded label.
  _IndianLanguage _selected = _kIndianLanguages.firstWhere(
        (lang) => lang.english == 'Tamil',
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      button: true,
      label: 'Change language, currently ${_selected.english}',
      child: PopupMenuButton<_IndianLanguage>(
        tooltip: 'Change language',
        position: PopupMenuPosition.under,
        onSelected: (lang) => setState(() => _selected = lang),
        itemBuilder: (context) => [
          for (final lang in _kIndianLanguages)
            PopupMenuItem<_IndianLanguage>(
              value: lang,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(lang.native),
                  if (lang == _selected)
                    const Padding(
                      padding: EdgeInsets.only(left: 10),
                      child: Icon(Icons.check_rounded, size: 16),
                    ),
                ],
              ),
            ),
        ],
        child: Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(100),
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.language_rounded, size: 18),
              const SizedBox(width: 6),
              Text(
                _selected.native,
                style: theme.textTheme.labelLarge?.copyWith(fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shown when location permission was refused.
///
/// The geofence cannot run without fixes, and the app must say so plainly
/// rather than showing a stationary boat and implying the alarm is armed.
class _PermissionWarning extends StatelessWidget {
  const _PermissionWarning();

  @override
  Widget build(BuildContext context) {
    return ActionCard(
      icon: Icons.location_off_rounded,
      accent: AppColors.danger,
      title: 'Location is off',
      subtitle: 'Boundary alarms cannot work without it. இருப்பிடம் தேவை.',
    );
  }
}

/// Displays active maritime persona and provides profile sheet & logout actions.
class _ProfileChip extends ConsumerWidget {
  const _ProfileChip();

  void _showProfileSheet(BuildContext context, WidgetRef ref) {
    final user = ref.read(currentUserProfileProvider);
    final theme = Theme.of(context);
    final role = user?.role ?? UserRole.fishermen;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSizes.radius)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 30,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.hairline,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: AppColors.deepSea.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
                      ),
                      child: Icon(role.icon, color: AppColors.deepSea, size: 28),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.displayName ?? 'Fisherman',
                            style: theme.textTheme.titleMedium,
                          ),
                          Text(
                            '${role.title.en} · ${role.title.ta}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: AppColors.deepSea,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 12),
                if (user?.assignedPort != null) ...[
                  _ProfileDetailRow(
                    icon: Icons.anchor_rounded,
                    label: 'Base Port',
                    value: user!.assignedPort!,
                  ),
                  const SizedBox(height: 8),
                ],
                if (user?.vesselRegistration != null) ...[
                  _ProfileDetailRow(
                    icon: Icons.directions_boat_rounded,
                    label: 'Vessel Reg',
                    value: user!.vesselRegistration!,
                  ),
                  const SizedBox(height: 8),
                ],
                _ProfileDetailRow(
                  icon: Icons.email_outlined,
                  label: 'Account',
                  value: user?.email ?? 'offline@orca.sea',
                ),
                const SizedBox(height: 8),
                _ProfileDetailRow(
                  icon: user?.isOffline == true ? Icons.cloud_off : Icons.cloud_done,
                  label: 'Session Mode',
                  value: user?.isOffline == true ? 'Offline Cache' : 'Supabase Cloud',
                ),
                const SizedBox(height: 24),
                FilledButton.tonalIcon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    ref.read(authProvider.notifier).signOut();
                  },
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text('Sign Out · வெளியேறு'),
                  style: FilledButton.styleFrom(
                    foregroundColor: AppColors.danger,
                    backgroundColor: AppColors.dangerSoft,
                    minimumSize: const Size.fromHeight(52),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProfileProvider);
    final theme = Theme.of(context);
    final role = user?.role ?? UserRole.fishermen;

    return Semantics(
      button: true,
      label: 'Profile: ${role.title.en}',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showProfileSheet(context, ref),
          borderRadius: BorderRadius.circular(100),
          child: Container(
            height: 34,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(100),
              border: Border.all(color: theme.colorScheme.outlineVariant),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(role.icon, size: 15, color: AppColors.deepSea),
                const SizedBox(width: 5),
                Flexible(
                  child: Text(
                    role.title.en,
                    style: theme.textTheme.labelLarge?.copyWith(fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                    softWrap: false,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileDetailRow extends StatelessWidget {
  const _ProfileDetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.inkMuted),
        const SizedBox(width: 10),
        Text('$label: ', style: theme.textTheme.bodyMedium),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 14.5,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}