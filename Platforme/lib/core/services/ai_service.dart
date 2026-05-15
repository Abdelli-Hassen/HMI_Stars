import 'package:google_generative_ai/google_generative_ai.dart';

/// Service for AI-powered content generation using Google Gemini.
class AiService {
  AiService._();

  static const String _apiKey = 'AIzaSyDnMfS_gFVJedOBVfzOixR_lWyHJHpFjBA';

  static final GenerativeModel _model = GenerativeModel(
    model: 'gemini-2.0-flash',
    apiKey: _apiKey,
  );

  /// Generate a warning/avertissement document based on context.
  static Future<String> generateAvertissement({
    required String contexte,
    required String nomEntreprise,
    String? nomSalarie,
    String type = 'avertissement',
  }) async {
    final prompt = '''
Tu es un assistant juridique RH professionnel spécialisé en droit du travail français.
Génère un document formel de type "$type" pour une entreprise.

Informations :
- Entreprise : $nomEntreprise
${nomSalarie != null ? '- Salarié concerné : $nomSalarie' : ''}
- Contexte / Motif : $contexte

Consignes :
- Rédige un document professionnel, formel et juridiquement correct.
- Utilise un ton ferme mais respectueux.
- Inclus la date du jour, les formules de politesse appropriées.
- Structure le document avec : objet, rappel des faits, décision/avertissement, conséquences en cas de récidive.
- Le document doit être prêt à imprimer et signer.
- Rédige UNIQUEMENT en français.
- Ne mets PAS de balises markdown, rédige en texte brut.
''';

    final content = [Content.text(prompt)];
    final response = await _model.generateContent(content);

    if (response.text == null || response.text!.isEmpty) {
      throw Exception('L\'IA n\'a pas pu générer de réponse.');
    }

    return response.text!;
  }
}
