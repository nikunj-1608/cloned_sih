import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/i18n/language_controller.dart';
import '../../core/i18n/login_translations.dart';
import '../../core/theme/app_theme.dart';
import 'auth_service.dart';
import 'language_drawer.dart';

/// Combined sign-in / sign-up screen backed by Supabase auth.
///
/// One screen rather than two: switching mode keeps the email and password
/// the person already typed, which matters on a phone keyboard. The full
/// name field only appears in sign-up mode, since it has no role in signing
/// an existing user in.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isSignUp = false;
  bool _obscurePassword = true;
  bool _submitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final lang = ref.read(languageProvider);
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _submitting = true;
      _errorMessage = null;
    });

    try {
      if (_isSignUp) {
        await AuthService.signUp(
          fullName: _nameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      } else {
        await AuthService.signIn(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      }
      // On success, AuthGate's session stream takes over navigation — nothing
      // to do here.
    } on AuthException catch (error) {
      setState(() => _errorMessage = error.message);
    } catch (error) {
      setState(
        () => _errorMessage = LoginText.of(lang, 'fillFieldsError'),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider);
    final theme = Theme.of(context);

    return Directionality(
      textDirection: lang.textDirection,
      child: Scaffold(
        drawer: const LanguageDrawer(),
        appBar: AppBar(
          automaticallyImplyLeading: false,
          leadingWidth: 160,
          leading: const LanguagesMenuButton(),
        ),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSizes.gutter),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 12),
                      Icon(
                        Icons.waves_rounded,
                        size: 56,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'ORCA',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        LoginText.of(lang, 'tagline'),
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 28),
                      Text(
                        LoginText.of(
                          lang,
                          _isSignUp ? 'createAccount' : 'welcomeBack',
                        ),
                        style: theme.textTheme.titleLarge,
                      ),
                      const SizedBox(height: 20),

                      // Full name — sign-up only.
                      if (_isSignUp) ...[
                        _LabelledField(
                          label: LoginText.of(lang, 'fullNameLabel'),
                          child: TextFormField(
                            controller: _nameController,
                            textInputAction: TextInputAction.next,
                            textCapitalization: TextCapitalization.words,
                            decoration: InputDecoration(
                              hintText: LoginText.of(lang, 'fullNameHint'),
                              prefixIcon: const Icon(
                                Icons.person_outline_rounded,
                              ),
                            ),
                            validator: (value) {
                              if (!_isSignUp) return null;
                              if (value == null || value.trim().isEmpty) {
                                return LoginText.of(lang, 'fillFieldsError');
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Email.
                      _LabelledField(
                        label: LoginText.of(lang, 'emailLabel'),
                        child: TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          decoration: InputDecoration(
                            hintText: LoginText.of(lang, 'emailHint'),
                            prefixIcon: const Icon(
                              Icons.alternate_email_rounded,
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return LoginText.of(lang, 'fillFieldsError');
                            }
                            final ok = RegExp(
                              r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                            ).hasMatch(value.trim());
                            return ok
                                ? null
                                : LoginText.of(lang, 'fillFieldsError');
                          },
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Password — masked by default, toggle to reveal.
                      _LabelledField(
                        label: LoginText.of(lang, 'passwordLabel'),
                        child: TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _submit(),
                          decoration: InputDecoration(
                            hintText: LoginText.of(lang, 'passwordHint'),
                            prefixIcon: const Icon(Icons.lock_outline_rounded),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                              onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword,
                              ),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.length < 6) {
                              return LoginText.of(lang, 'fillFieldsError');
                            }
                            return null;
                          },
                        ),
                      ),

                      if (_errorMessage != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          _errorMessage!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.error,
                          ),
                        ),
                      ],

                      const SizedBox(height: 24),
                      FilledButton(
                        onPressed: _submitting ? null : _submit,
                        child: _submitting
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.4,
                                ),
                              )
                            : Text(
                                LoginText.of(
                                  lang,
                                  _isSignUp ? 'signUp' : 'signIn',
                                ),
                              ),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: _submitting
                            ? null
                            : () => setState(() {
                                _isSignUp = !_isSignUp;
                                _errorMessage = null;
                              }),
                        child: Text(
                          LoginText.of(
                            lang,
                            _isSignUp ? 'switchToSignIn' : 'switchToSignUp',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A field with its label above it, matching the "user-friendly separated
/// boxes" brief rather than relying on a floating label alone.
class _LabelledField extends StatelessWidget {
  const _LabelledField({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 6, left: 2),
          child: Text(label, style: theme.textTheme.titleMedium),
        ),
        child,
      ],
    );
  }
}
