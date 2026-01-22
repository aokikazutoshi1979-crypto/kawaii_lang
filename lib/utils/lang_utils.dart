String getLangCode(String lang) {
  switch (lang) {
    case 'Japanese':
    case '日本語':
    case 'ja':
      return 'ja';

    case 'English':
    case '英語':
    case 'en':
      return 'en';

    case 'Chinese (Simplified)':
    case '中文':
    case 'zh':
      return 'zh';

    case 'Chinese (Traditional, Taiwan)':
    case '中文（繁體字）':
    case '中文（台湾）':
    case 'zh_TW':
      return 'zh_TW';

    case 'Korean':
    case '한국어':
    case 'ko':
      return 'ko';

    case 'Spanish':
    case 'Español':
    case 'es':
      return 'es';

    case 'French':
    case 'Français':
    case 'fr':
      return 'fr';

    case 'German':
    case 'Deutsch':
    case 'de':
      return 'de';

    case 'Vietnamese':
    case 'Tiếng Việt':
    case 'vi':
      return 'vi';

    case 'Indonesian':
    case 'Bahasa Indonesia':
    case 'id':
      return 'id';

    default:
      return 'en';
  }
}

String getLocaleId(String lang) {
  switch (lang) {
    case 'Japanese':
    case '日本語':
    case 'ja':
      return 'ja-JP';

    case 'English':
    case '英語':
    case 'en':
      return 'en-US';

    case 'Chinese (Simplified)':
    case '中文':
    case 'zh':
      return 'zh-CN';

    case 'Chinese (Traditional, Taiwan)':
    case '中文（繁體字）':
    case 'zh_TW':
      return 'zh_TW';

    case 'Korean':
    case '한국어':
    case 'ko':
      return 'ko-KR';

    case 'Spanish':
    case 'Español':
    case 'es':
      return 'es-ES';

    case 'French':
    case 'Français':
    case 'fr':
      return 'fr-FR';

    case 'German':
    case 'Deutsch':
    case 'de':
      return 'de-DE';

    case 'Vietnamese':
    case 'Tiếng Việt':
    case 'vi':
      return 'vi-VN';

    case 'Indonesian':
    case 'Bahasa Indonesia':
    case 'id':
      return 'id-ID';

    default:
      return 'en-US';
  }
}

String getLangLabel(String code) {
  switch (code) {
    case 'ja':
      return '日本語';
    case 'en':
      return 'English';
    case 'zh':
      return '中文（簡体字）';
    case 'zh_TW':
      return '中文（繁體字／台湾）';
    case 'ko':
      return '한국어';
    case 'es':
      return 'Español';
    case 'fr':
      return 'Français';
    case 'de':
      return 'Deutsch';
    case 'vi':
      return 'Tiếng Việt';
    case 'id':
      return 'Bahasa Indonesia';
    default:
      return code;
  }
}

// 追加: 英語表記（GPT用）
String getLangLabelEn(String code) {
  switch (code) {
    case 'ja':   return 'Japanese';
    case 'en':   return 'English';
    case 'zh':   return 'Chinese (Simplified)';
    case 'zh_TW':return 'Chinese (Traditional, Taiwan)';
    case 'ko':   return 'Korean';
    case 'es':   return 'Spanish';
    case 'fr':   return 'French';
    case 'de':   return 'German';
    case 'vi':   return 'Vietnamese';
    case 'id':   return 'Indonesian';
    default:     return code;
  }
}