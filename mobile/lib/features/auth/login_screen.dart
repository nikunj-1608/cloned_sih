import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/env.dart';
import '../../core/l10n/login_l10n.dart';
import '../../core/models/user_role.dart';
import '../../core/providers/language_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import 'auth_controller.dart';
import 'widgets/role_selector_card.dart';

/// The ORCA Login and Registration Screen.
///
/// Implements Role-Based Access Control (RBAC) authentication across 5 maritime
/// profiles (Fishermen, Researchers, Coastal Authorities, Disaster Management,
/// and Maritime Operators). Authenticates against Supabase Auth with offline-first
/// fallback at sea or when keys are unconfigured.
///
/// Language is driven by [languageProvider] (persisted in SharedPreferences).
/// A hamburger button in the top-right corner opens a [_LanguageDrawer] with
/// all 23 languages (22 scheduled Indian + English).
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  late final TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
    _nameController = TextEditingController();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final auth = ref.read(authProvider.notifier);
    final isSignUp = ref.read(authProvider.select((s) => s.isSignUp));

    if (isSignUp) {
      await auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        fullName: _nameController.text.trim(),
      );
    } else {
      await auth.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
    }
  }

  void _showRolePickerModal(
    BuildContext context,
    UserRole selectedRole,
    LoginL10n l10n,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppSizes.radius)),
      ),
      builder: (modalContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.hairline,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.selectProfile,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: UserRole.values.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 10),
                    itemBuilder: (ctx, index) {
                      final role = UserRole.values[index];
                      return RoleSelectorCard(
                        role: role,
                        isSelected: role == selectedRole,
                        localizedTitle: _roleTitle(role, l10n),
                        localizedDesc: _roleDesc(role, l10n),
                        onSelect: () {
                          ref.read(authProvider.notifier).selectRole(role);
                          Navigator.pop(ctx);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _roleTitle(UserRole role, LoginL10n l10n) => switch (role) {
        UserRole.fishermen => l10n.roleFisherman,
        UserRole.researchers => l10n.roleResearcher,
        UserRole.coastalAuthorities => l10n.roleCoastalAuthority,
        UserRole.disasterManagement => l10n.roleDisasterMgmt,
        UserRole.maritimeOperators => l10n.roleMaritimeOperator,
      };

  String _roleDesc(UserRole role, LoginL10n l10n) => switch (role) {
        UserRole.fishermen => l10n.descFisherman,
        UserRole.researchers => l10n.descResearcher,
        UserRole.coastalAuthorities => l10n.descCoastalAuthority,
        UserRole.disasterManagement => l10n.descDisasterMgmt,
        UserRole.maritimeOperators => l10n.descMaritimeOperator,
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = ref.watch(authProvider);
    final selectedRole = authState.selectedRole;
    final isSignUp = authState.isSignUp;
    final isLoading = authState.isLoading;

    final lang = ref.watch(languageProvider);
    final l10n = LoginL10n.of(lang);

    return Scaffold(
      endDrawer: _LanguageDrawer(currentLang: lang),
      body: Stack(
        children: [
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.gutter,
                  vertical: 24,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Brand Crest & Header
                        _buildHeader(theme, l10n),
                        const SizedBox(height: 20),

                        // Error Notification if any
                        if (authState.errorMessage != null) ...[
                          _buildErrorBanner(theme, authState.errorMessage!),
                          const SizedBox(height: 16),
                        ],

                        // Input Fields
                        if (isSignUp) ...[
                          _buildNameField(theme, l10n),
                          const SizedBox(height: 16),
                        ],
                        _buildEmailField(theme, l10n),
                        const SizedBox(height: 16),
                        _buildPasswordField(
                            theme, authState.obscurePassword, l10n),
                        const SizedBox(height: 20),

                        // Role Selection — below the text fields
                        _buildRoleSection(theme, selectedRole, l10n),
                        const SizedBox(height: 20),

                        // Main Action Button (64dp target)
                        _buildSubmitButton(theme, isSignUp, isLoading, l10n),
                        const SizedBox(height: 16),

                        // Toggle Sign In / Sign Up Mode
                        _buildModeToggle(theme, isSignUp, l10n),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Hamburger / language picker button — top-right overlay
          Positioned(
            top: 0,
            right: 0,
            child: SafeArea(
              child: Builder(
                builder: (ctx) => IconButton(
                  tooltip: l10n.selectLanguage,
                  icon: const Icon(Icons.menu_rounded),
                  color: AppColors.deepSea,
                  onPressed: () => Scaffold.of(ctx).openEndDrawer(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, LoginL10n l10n) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: AppColors.deepSea.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(18),
            border:
                Border.all(color: AppColors.deepSea.withValues(alpha: 0.2)),
          ),
          child: const Center(
            child: Icon(
              Icons.tsunami_rounded,
              size: 36,
              color: AppColors.deepSea,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'ORCA',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
            color: AppColors.deepSea,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          l10n.appSubtitle,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.inkMuted,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        // Offline / Supabase Status Pill
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Env.hasSupabaseConfig
                ? AppColors.safeSoft
                : AppColors.cautionSoft,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Env.hasSupabaseConfig ? Icons.cloud_done : Icons.cloud_off,
                size: 14,
                color: Env.hasSupabaseConfig
                    ? AppColors.safe
                    : AppColors.caution,
              ),
              const SizedBox(width: 6),
              Text(
                Env.hasSupabaseConfig
                    ? l10n.cloudConnected
                    : l10n.offlineMode,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Env.hasSupabaseConfig
                      ? AppColors.safe
                      : AppColors.caution,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRoleSection(
    ThemeData theme,
    UserRole selectedRole,
    LoginL10n l10n,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.activeProfile,
                style: theme.textTheme.labelLarge?.copyWith(fontSize: 15),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            TextButton.icon(
              onPressed: () =>
                  _showRolePickerModal(context, selectedRole, l10n),
              icon: const Icon(Icons.swap_horiz, size: 18),
              label: Text(l10n.change),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                visualDensity: VisualDensity.compact,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        RoleSelectorCard(
          role: selectedRole,
          isSelected: true,
          localizedTitle: _roleTitle(selectedRole, l10n),
          localizedDesc: _roleDesc(selectedRole, l10n),
          onSelect: () => _showRolePickerModal(context, selectedRole, l10n),
        ),
      ],
    );
  }

  Widget _buildErrorBanner(ThemeData theme, String message) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.dangerSoft,
        borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: AppColors.danger, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppColors.danger,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18, color: AppColors.danger),
            onPressed: () => ref.read(authProvider.notifier).clearError(),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildNameField(ThemeData theme, LoginL10n l10n) {
    return TextFormField(
      controller: _nameController,
      textCapitalization: TextCapitalization.words,
      decoration: InputDecoration(
        labelText: l10n.fullName,
        hintText: l10n.fullNameHint,
        prefixIcon: const Icon(Icons.person_outline_rounded),
        filled: true,
        fillColor: theme.cardTheme.color,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
          borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      validator: (val) {
        if (val == null || val.trim().isEmpty) return l10n.nameRequired;
        return null;
      },
    );
  }

  Widget _buildEmailField(ThemeData theme, LoginL10n l10n) {
    return TextFormField(
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      autocorrect: false,
      decoration: InputDecoration(
        labelText: l10n.email,
        hintText: l10n.emailHint,
        prefixIcon: const Icon(Icons.email_outlined),
        filled: true,
        fillColor: theme.cardTheme.color,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
          borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      validator: (val) {
        if (val == null || val.trim().isEmpty) return l10n.emailRequired;
        if (!val.contains('@') || !val.contains('.')) {
          return l10n.emailInvalid;
        }
        return null;
      },
    );
  }

  Widget _buildPasswordField(
      ThemeData theme, bool obscure, LoginL10n l10n) {
    return TextFormField(
      controller: _passwordController,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: l10n.password,
        hintText: l10n.passwordHint,
        prefixIcon: const Icon(Icons.lock_outline_rounded),
        suffixIcon: IconButton(
          icon: Icon(
            obscure
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
          ),
          onPressed: () =>
              ref.read(authProvider.notifier).togglePasswordVisibility(),
        ),
        filled: true,
        fillColor: theme.cardTheme.color,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
          borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      validator: (val) {
        if (val == null || val.isEmpty) return l10n.passwordRequired;
        if (val.length < 6) return l10n.passwordTooShort;
        return null;
      },
    );
  }

  Widget _buildSubmitButton(
      ThemeData theme, bool isSignUp, bool isLoading, LoginL10n l10n) {
    return SizedBox(
      height: AppSizes.tapTarget,
      child: FilledButton(
        onPressed: isLoading ? null : _submit,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.deepSea,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 26,
                height: 26,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(isSignUp
                      ? Icons.person_add_rounded
                      : Icons.login_rounded),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      isSignUp ? l10n.createAccount : l10n.logIn,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildModeToggle(ThemeData theme, bool isSignUp, LoginL10n l10n) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          isSignUp ? l10n.alreadyHaveAccount : l10n.dontHaveAccount,
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(width: 4),
        TextButton(
          onPressed: () => ref.read(authProvider.notifier).toggleMode(),
          child: Text(
            isSignUp ? l10n.logIn : l10n.signUp,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: AppColors.deepSea,
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Language selector drawer
// ─────────────────────────────────────────────────────────────────────────────

class _LanguageDrawer extends ConsumerWidget {
  const _LanguageDrawer({required this.currentLang});

  final AppLanguage currentLang;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = LoginL10n.of(currentLang);

    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Text(
                l10n.selectLanguage,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.deepSea,
                ),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                itemCount: AppLanguage.values.length,
                itemBuilder: (context, index) {
                  final lang = AppLanguage.values[index];
                  final isSelected = lang == currentLang;

                  return ListTile(
                    selected: isSelected,
                    selectedTileColor:
                        AppColors.deepSea.withValues(alpha: 0.08),
                    title: Text(
                      lang.nativeName,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: isSelected ? AppColors.deepSea : null,
                      ),
                    ),
                    subtitle: lang.nativeName != lang.englishName
                        ? Text(
                            lang.englishName,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.inkMuted,
                            ),
                          )
                        : null,
                    trailing: isSelected
                        ? const Icon(Icons.check_circle_rounded,
                            color: AppColors.deepSea)
                        : null,
                    onTap: () {
                      ref
                          .read(languageProvider.notifier)
                          .setLanguage(lang);
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
