import 'package:doomread/data/repositories/auth_repository.dart';
import 'package:doomread/data/repositories/sync_repository.dart';
import 'package:doomread/data/repositories/work_repository.dart';
import 'package:doomread/domain/use_cases/stop_deleted_sessions_use_case.dart';
import 'package:doomread/utils/result.dart';

/// Syncs the signed-in account, and does what a sync means for the other
/// repositories, which never use each other: a sign-in the server ended
/// signs this device out, a device left with no current Work picks the
/// most recently changed one (ADR-0012), and a Session left open on a Work
/// deleted elsewhere is stopped.
///
/// A use case in the official guide's sense: logic across repositories.
class SyncUseCase {
  SyncUseCase(this._auth, this._sync, this._works, this._stopDeleted);

  final AuthRepository _auth;
  final SyncRepository _sync;
  final WorkRepository _works;
  final StopDeletedSessionsUseCase _stopDeleted;

  Future<Result<void>> call() async {
    final token = await _auth.token();
    final username = await _auth.username();
    if (token == null || username == null) {
      return const Result.error(SyncException(SyncFailure.signedOut));
    }
    final result = await _sync.sync(username: username, token: token);
    switch (result) {
      case Ok():
        await _works.keepOneCurrent();
        await _stopDeleted();
      case Error(error: SyncException(failure: SyncFailure.signInEnded)):
        await _auth.signOut();
      case Error():
    }
    return result;
  }
}
