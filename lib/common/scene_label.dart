// lib/common/scene_label.dart
import 'package:kawaii_lang/l10n/app_localizations.dart';

String sceneLabel(String scene, AppLocalizations loc) {
  switch (scene) {
    case 'trial': return loc.sceneTrial;
    case 'vocabulary': return loc.sceneVocabulary;
    case 'greeting': return loc.sceneGreeting;
    case 'travel': return loc.sceneTravel;
    case 'restaurant': return loc.sceneRestaurant;
    case 'shopping': return loc.sceneShopping;
    case 'dating': return loc.sceneDating;
    case 'culture_entertainment': return loc.sceneculture_entertainment;
    case 'community_life': return loc.scenecommunity_life;
    case 'work': return loc.sceneWork;
    case 'Social_interactions_hobbies': return loc.sceneSocial_interactions_hobbies;
    default: return scene;
  }
}
