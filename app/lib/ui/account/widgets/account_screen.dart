import 'package:doomread/data/repositories/auth_repository.dart';
import 'package:doomread/l10n/app_localizations.dart';
import 'package:doomread/ui/account/view_models/account_view_model.dart';
import 'package:doomread_core/accounts.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Sign up, sign in and sign out. Expects an [AccountViewModel] above it.
class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final _username = TextEditingController();
  final _password = TextEditingController();

  AccountViewModel get _vm => context.read<AccountViewModel>();

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  Credentials get _credentials => Credentials(
    // Phone keyboards like to capitalise the first letter.
    username: _username.text.trim().toLowerCase(),
    password: _password.text,
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.account)),
      body: ListenableBuilder(
        listenable: Listenable.merge([_vm, _vm.signIn, _vm.signUp]),
        builder: (context, _) => ListView(
          padding: const EdgeInsetsDirectional.fromSTEB(24, 8, 24, 24),
          children: [
            if (_vm.username case final name?)
              ..._signedIn(context, name)
            else
              ..._signedOut(context),
          ],
        ),
      ),
    );
  }

  List<Widget> _signedIn(BuildContext context, String name) {
    final l10n = AppLocalizations.of(context);
    return [
      Text(
        l10n.accountSignedInAs(name),
        style: Theme.of(context).textTheme.titleMedium,
      ),
      const SizedBox(height: 24),
      Align(
        alignment: AlignmentDirectional.centerStart,
        child: OutlinedButton(
          onPressed: _vm.signOut.execute,
          child: Text(l10n.accountSignOut),
        ),
      ),
    ];
  }

  List<Widget> _signedOut(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final busy = _vm.signIn.running || _vm.signUp.running;
    final failure = _vm.failure;
    return [
      Text(l10n.accountSignedOutHint, style: theme.textTheme.bodyMedium),
      const SizedBox(height: 24),
      TextField(
        controller: _username,
        decoration: InputDecoration(labelText: l10n.accountUsername),
        autocorrect: false,
        enableSuggestions: false,
        // Usernames are Latin even when the app is in Persian.
        textDirection: TextDirection.ltr,
        autofillHints: const [AutofillHints.username],
        textInputAction: TextInputAction.next,
      ),
      const SizedBox(height: 12),
      TextField(
        controller: _password,
        decoration: InputDecoration(labelText: l10n.accountPassword),
        obscureText: true,
        textDirection: TextDirection.ltr,
        autofillHints: const [AutofillHints.password],
      ),
      if (failure != null) ...[
        const SizedBox(height: 12),
        Text(
          _message(l10n, failure),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.error,
          ),
        ),
      ],
      const SizedBox(height: 24),
      Row(
        children: [
          FilledButton(
            onPressed: busy ? null : () => _vm.signIn.execute(_credentials),
            child: Text(l10n.accountSignIn),
          ),
          const SizedBox(width: 12),
          TextButton(
            onPressed: busy ? null : () => _vm.signUp.execute(_credentials),
            child: Text(l10n.accountSignUp),
          ),
        ],
      ),
    ];
  }

  static String _message(AppLocalizations l10n, AuthFailure failure) =>
      switch (failure) {
        AuthFailure.username => l10n.accountErrorUsername,
        AuthFailure.password => l10n.accountErrorPassword,
        AuthFailure.usernameTaken => l10n.accountErrorTaken,
        AuthFailure.wrongCredentials => l10n.accountErrorWrong,
        AuthFailure.rejected => l10n.accountErrorRejected,
        AuthFailure.unreachable => l10n.accountErrorUnreachable,
      };
}
