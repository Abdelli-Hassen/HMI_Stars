import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/services/platform_auth_service.dart';
import '../../../../core/services/platform_data_service.dart';
import '../../../../core/router/app_router.dart';
import '../../domain/models/platform_user.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthProvider extends ChangeNotifier {
  final _authService = PlatformAuthService();
  final _dataService = PlatformDataService();

  AuthStatus _status = AuthStatus.initial;
  String? _errorMessage;
  User? _user;
  UtilisateurPlateforme? _utilisateur;
  bool _emailNonConfirme = false;
  String? _emailEnAttente;
  String _tempLanguage = 'Français (FR)';

  String get tempLanguage => _tempLanguage;

  void setTempLanguage(String lang) {
    _tempLanguage = lang;
    notifyListeners();
  }

  AuthStatus get status => _status;
  String? get errorMessage => _errorMessage;
  User? get user => _user;
  UtilisateurPlateforme? get utilisateur => _utilisateur;
  bool get isAuthenticated => _status == AuthStatus.authenticated && _user != null && _utilisateur != null;
  bool get emailNonConfirme => _emailNonConfirme;
  String? get emailEnAttente => _emailEnAttente;

  String get userRole => _utilisateur?.role ?? 'inconnu';
  bool get isAdmin => _utilisateur?.role == 'admin';
  String get libelleRole => _utilisateur?.libelleRole ?? 'Inconnu';
  String get userName => _utilisateur?.nom ?? _user?.email?.split('@')[0] ?? 'Utilisateur';
  String get userEmail => _utilisateur?.email ?? _user?.email ?? '';
  String get userPhone => _utilisateur?.telephone ?? '';
  String get userCin => _utilisateur?.cin ?? '';
  String get userOrganisation => _utilisateur?.organisation ?? 'HMI Stars Consulting';
  String? get userAvatarUrl => _utilisateur?.avatarUrl;

  AuthProvider() {
    _init();
  }

  Future<void> _init() async {
    debugPrint('[AuthProvider] init');

    // 1. Listen to auth state changes first
    _authService.onAuthStateChange.listen((state) async {
      debugPrint('[AuthProvider] Auth event: ${state.event}');
      if (state.event == AuthChangeEvent.passwordRecovery) {
        _user = state.session?.user;
        _status = AuthStatus.unauthenticated;
        _errorMessage = null;
        notifyListeners();
        _navigateToResetPassword();
        return;
      }

      if (state.session?.user != null) {
        _user = state.session!.user;
        await _verifierEtChargerProfil();
      } else {
        _user = null;
        _utilisateur = null;
        _status = AuthStatus.unauthenticated;
      }
      _errorMessage = null;
      notifyListeners();
    });

    // 2. If recovery flow is detected in the URL, return early to keep the token session
    final isRecovery = Uri.base.toString().contains('recovery');
    if (isRecovery) {
      debugPrint('[AuthProvider] Recovery flow detected, skipping initial checks');
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final rememberMe = prefs.getBool('remember_me') ?? false;
      if (!rememberMe) {
        debugPrint('[AuthProvider] remember_me is false, clearing initial session');
        await _authService.signOut();
      }
    } catch (e) {
      debugPrint('[AuthProvider] Error reading remember_me: $e');
    }

    final session = _authService.currentSession;

    if (session == null || session.isExpired) {
      debugPrint('[AuthProvider] No valid session');
      _user = null;
      _status = AuthStatus.unauthenticated;
      await _authService.signOut();
      notifyListeners();
      return;
    }

    _user = _authService.currentUser;
    debugPrint('[AuthProvider] Session found: ${_user?.email}');

    try {
      _utilisateur = await _dataService.recupererUtilisateur(_user!.id);
    } catch (e) {
      debugPrint('[AuthProvider] Error loading profile: $e');
    }

    if (_utilisateur != null) {
      debugPrint('[AuthProvider] Profile OK: ${_utilisateur!.nom} (${_utilisateur!.libelleRole})');
      _status = AuthStatus.authenticated;
    } else {
      debugPrint('[AuthProvider] No profile found -> access denied');
      _user = null;
      _status = AuthStatus.unauthenticated;
      await _authService.signOut();
    }

    notifyListeners();
  }

  /// Vérifie que l'utilisateur a un profil valide dans la base.
  /// Si le profil n'existe pas → déconnexion forcée.
  Future<void> _verifierEtChargerProfil() async {
    if (_user == null) return;
    try {
      _utilisateur = await _dataService.recupererUtilisateur(_user!.id);
      if (_utilisateur != null) {
        _status = AuthStatus.authenticated;
      } else {
        debugPrint('[AuthProvider] Profile not found -> signing out');
        _status = AuthStatus.unauthenticated;
        _user = null;
        await _authService.signOut();
      }
    } catch (e) {
      debugPrint('[AuthProvider] Error verifying profile: $e');
      _status = AuthStatus.unauthenticated;
      _user = null;
      await _authService.signOut();
    }
    notifyListeners();
  }

  Future<bool> signIn({
    required String email,
    required String password,
    bool rememberMe = false,
  }) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('remember_me', rememberMe);
      } catch (e) {
        debugPrint('[AuthProvider] Error saving remember_me: $e');
      }

      final response = await _authService.signIn(
        email: email,
        password: password,
      );
      _user = response.user;

      if (_user == null) {
        _status = AuthStatus.unauthenticated;
        _errorMessage = 'Identifiants invalides.';
        notifyListeners();
        return false;
      }

      // Vérifier le profil en base
      _utilisateur = await _dataService.recupererUtilisateur(_user!.id);
      if (_utilisateur == null) {
        _status = AuthStatus.error;
        _errorMessage = 'Ce compte n\'est pas autorisé à accéder à la plateforme.';
        _user = null;
        await _authService.signOut();
        notifyListeners();
        return false;
      }

      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _status = AuthStatus.error;
      if (e.message.contains('Email not confirmed') ||
          (e is AuthApiException && e.code == 'email_not_confirmed')) {
        _emailNonConfirme = true;
        _emailEnAttente = email;
        _errorMessage = 'Votre adresse e-mail n\'a pas encore été confirmée.';
      } else {
        _errorMessage = e.message;
      }
      notifyListeners();
      return false;
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = 'Erreur de connexion. Vérifiez votre réseau.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> signUp({
    required String email,
    required String password,
    String? nom,
    String? telephone,
    String? cin,
    String? organisation,
  }) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _authService.signUp(
        email: email,
        password: password,
        nom: nom,
        telephone: telephone,
        cin: cin,
        organisation: organisation,
      );
      _user = response.user;

      if (_user == null) {
        _status = AuthStatus.error;
        _errorMessage = 'Erreur lors de la création du compte.';
        notifyListeners();
        return false;
      }

      if (response.session == null) {
        // L'utilisateur est créé mais doit vérifier son email
        _status = AuthStatus.unauthenticated;
        _errorMessage = 'Inscription réussie. Veuillez vérifier votre boîte mail pour confirmer votre compte.';
        notifyListeners();
        return true;
      }

      // Si la session existe (par exemple si Confirm email est désactivé dans Supabase)
      // Charger le profil créé par le trigger DB
      _utilisateur = await _dataService.recupererUtilisateur(_user!.id);
      if (_utilisateur == null) {
        // Le trigger n'a pas encore créé le profil → attendre un peu
        debugPrint('[AuthProvider] Profile not found after signup, retrying...');
        await Future.delayed(const Duration(milliseconds: 500));
        _utilisateur = await _dataService.recupererUtilisateur(_user!.id);
      }

      if (_utilisateur != null) {
        _status = AuthStatus.authenticated;
      } else {
        _status = AuthStatus.error;
        _errorMessage = 'Le profil n\'a pas pu être créé. Contactez l\'administrateur.';
        _user = null;
        await _authService.signOut();
      }

      notifyListeners();
      return _utilisateur != null;
    } on AuthException catch (e) {
      _status = AuthStatus.error;
      _errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = 'Erreur lors de la création du compte.';
      notifyListeners();
      return false;
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      await _authService.resetPassword(email);
    } on AuthException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
    }
  }

  Future<bool> verifyRecoveryOTP(String email, String token) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();
    try {
      final response = await _authService.verifyRecoveryOTP(email, token);
      _user = response.user;
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _status = AuthStatus.error;
      _errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = 'Code invalide ou expiré.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> verifySignupOTP(String email, String token) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();
    try {
      final response = await _authService.verifySignupOTP(email, token);
      _user = response.user;
      
      _utilisateur = await _dataService.recupererUtilisateur(_user!.id);
      if (_utilisateur == null) {
        await Future.delayed(const Duration(milliseconds: 500));
        _utilisateur = await _dataService.recupererUtilisateur(_user!.id);
      }

      if (_utilisateur != null) {
        _status = AuthStatus.authenticated;
        _emailNonConfirme = false;
        _emailEnAttente = null;
        _errorMessage = null;
      } else {
        _status = AuthStatus.error;
        _errorMessage = 'Le profil n\'a pas pu être créé. Contactez l\'administrateur.';
        _user = null;
        await _authService.signOut();
      }

      notifyListeners();
      return _utilisateur != null;
    } on AuthException catch (e) {
      _status = AuthStatus.error;
      _errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = 'Code invalide ou expiré.';
      notifyListeners();
      return false;
    }
  }

  Future<void> updateEmail(String newEmail) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();
    try {
      await _authService.updateEmail(newEmail);
      _status = AuthStatus.unauthenticated;
      notifyListeners();
    } on AuthException catch (e) {
      _status = AuthStatus.error;
      _errorMessage = e.message;
      notifyListeners();
      rethrow;
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = 'Erreur lors de la modification de l\'e-mail.';
      notifyListeners();
      rethrow;
    }
  }

  Future<bool> verifyEmailChangeOTP(String newEmail, String token) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();
    try {
      await _authService.verifyEmailChangeOTP(newEmail, token);
      
      if (_utilisateur != null) {
        _utilisateur = await _dataService.mettreAJourUtilisateur(
          _utilisateur!.copyWith(email: newEmail),
        );
      }
      
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _status = AuthStatus.error;
      _errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = 'Code invalide ou expiré.';
      notifyListeners();
      return false;
    }
  }

  /// Change the current user's password via Supabase Auth.
  Future<void> changePassword(String newPassword) async {
    await _authService.updatePassword(newPassword);
  }

  /// Verifies the current user's password.
  Future<bool> verifyCurrentPassword(String password) async {
    try {
      await _authService.signIn(email: userEmail, password: password);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> signOut() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('remember_me');
    } catch (e) {
      debugPrint('[AuthProvider] Error clearing remember_me on signOut: $e');
    }
    await _authService.signOut();
    _user = null;
    _utilisateur = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    _emailNonConfirme = false;
    _emailEnAttente = null;
    notifyListeners();
  }

  /// Renvoyer l'e-mail de confirmation pour un compte non vérifié.
  Future<bool> renvoyerConfirmation() async {
    if (_emailEnAttente == null) return false;
    try {
      await _authService.resendConfirmationEmail(_emailEnAttente!);
      _emailNonConfirme = false;
      _errorMessage = null;
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Impossible de renvoyer l\'e-mail. Réessayez plus tard.';
      notifyListeners();
      return false;
    }
  }

  /// Sauvegarder les modifications du profil.
  Future<void> updateUser(String nom, String role, String email, {String? telephone, String? cin, String? organisation, Map<String, dynamic>? preferences}) async {
    if (_utilisateur == null) return;
    try {
      _utilisateur = await _dataService.mettreAJourUtilisateur(
        _utilisateur!.copyWith(
          nom: nom, 
          email: email, 
          role: role,
          telephone: telephone,
          cin: cin,
          organisation: organisation,
          preferences: preferences,
        ),
      );
      notifyListeners();
    } catch (e) {
      debugPrint('[AuthProvider] Error updating profile: $e');
    }
  }

  // ─── ADMIN: Gestion des Comptes ───────────────────────────────────────────

  /// Récupère tous les utilisateurs de la plateforme (Admin uniquement).
  Future<List<UtilisateurPlateforme>> fetchAllUsers() async {
    if (!isAdmin) return [];
    return await _dataService.recupererTousUtilisateurs();
  }

  /// Change le rôle d'un utilisateur cible (Admin uniquement).
  Future<void> changeUserRole(String userId, String newRole) async {
    if (!isAdmin) return;
    try {
      final user = await _dataService.recupererUtilisateur(userId);
      if (user != null) {
        await _dataService.mettreAJourUtilisateur(user.copyWith(role: newRole));
      }
    } catch (e) {
      debugPrint('[AuthProvider] Error changing role: $e');
    }
  }

  /// Supprime définitivement un utilisateur (Admin uniquement).
  Future<void> deleteUser(String userId) async {
    if (!isAdmin) return;
    try {
      await _dataService.supprimerUtilisateurAuth(userId);
    } catch (e) {
      debugPrint('[AuthProvider] Error deleting user: $e');
      rethrow;
    }
  }

  /// Mettre à jour le téléphone, l'organisation et les préférences.
  Future<void> mettreAJourProfil({
    String? nom,
    String? telephone,
    String? organisation,
    Map<String, dynamic>? preferences,
  }) async {
    if (_utilisateur == null) return;
    try {
      _utilisateur = await _dataService.mettreAJourUtilisateur(
        _utilisateur!.copyWith(
          nom: nom ?? _utilisateur!.nom,
          email: _utilisateur!.email,
          role: _utilisateur!.role,
          telephone: telephone ?? _utilisateur!.telephone,
          organisation: organisation ?? _utilisateur!.organisation,
          preferences: preferences ?? _utilisateur!.preferences,
        ),
      );
      notifyListeners();
    } catch (e) {
      debugPrint('[AuthProvider] Error updating profile: $e');
    }
  }

  /// Upload un avatar et met à jour le profil local.
  Future<bool> uploadAvatar(Uint8List fileBytes, String fileName) async {
    if (_utilisateur == null) return false;
    try {
      final url = await _dataService.uploadAvatar(_utilisateur!.id, fileBytes, fileName);
      if (url != null) {
        _utilisateur = _utilisateur!.copyWith(avatarUrl: url);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('[AuthProvider] Error uploading avatar: $e');
      return false;
    }
  }

  void _navigateToResetPassword() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndNavigate();
    });
  }

  void _checkAndNavigate() {
    final navigator = AppRoutes.navigatorKey.currentState;
    if (navigator != null) {
      navigator.pushNamedAndRemoveUntil(
        AppRoutes.resetPassword,
        (route) => false,
      );
    } else {
      Future.delayed(const Duration(milliseconds: 100), _checkAndNavigate);
    }
  }
}
