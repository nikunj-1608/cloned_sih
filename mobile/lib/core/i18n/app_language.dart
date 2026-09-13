import 'package:flutter/material.dart';

/// The 22 languages listed in the Eighth Schedule of the Indian Constitution,
/// plus English. Each entry carries its own name in its own script — a
/// speaker looking for their language in a long list should be able to spot
/// it by shape, not by reading English first.
enum AppLanguage {
  assamese('as', 'Assamese', 'অসমীয়া'),
  bengali('bn', 'Bengali', 'বাংলা'),
  bodo('brx', 'Bodo', 'बड़ो'),
  dogri('doi', 'Dogri', 'डोगरी'),
  gujarati('gu', 'Gujarati', 'ગુજરાતી'),
  hindi('hi', 'Hindi', 'हिन्दी'),
  kannada('kn', 'Kannada', 'ಕನ್ನಡ'),
  kashmiri('ks', 'Kashmiri', 'कॉशुर'),
  konkani('kok', 'Konkani', 'कोंकणी'),
  malayalam('ml', 'Malayalam', 'മലയാളം'),
  manipuri('mni', 'Manipuri', 'মৈতৈলোন্'),
  marathi('mr', 'Marathi', 'मराठी'),
  maithili('mai', 'Maithili', 'मैथिली'),
  nepali('ne', 'Nepali', 'नेपाली'),
  oriya('or', 'Odia', 'ଓଡ଼ିଆ'),
  punjabi('pa', 'Punjabi', 'ਪੰਜਾਬੀ'),
  sanskrit('sa', 'Sanskrit', 'संस्कृतम्'),
  santhali('sat', 'Santhali', 'ᱥᱟᱱᱛᱟᱲᱤ'),
  sindhi('sd', 'Sindhi', 'سنڌي'),
  tamil('ta', 'Tamil', 'தமிழ்'),
  telugu('te', 'Telugu', 'తెలుగు'),
  urdu('ur', 'Urdu', 'اردو'),
  english('en', 'English', 'English');

  const AppLanguage(this.code, this.englishName, this.nativeName);

  final String code;
  final String englishName;
  final String nativeName;

  /// Urdu (and Kashmiri, when rendered in its Perso-Arabic form) read
  /// right-to-left. Only Urdu is set that way here since the rest of this
  /// screen's Kashmiri copy uses Devanagari.
  TextDirection get textDirection =>
      this == AppLanguage.urdu ? TextDirection.rtl : TextDirection.ltr;
}
