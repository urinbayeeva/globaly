import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const Color brand = Color(0xFFDC1F2E);
  static const Color brand700 = Color(0xFF8E121C);
  static const Color brand100 = Color(0xFFFEECEE);
  static const Color brand200 = Color(0xFFFCD0D5);
  static const Color brand300 = Color(0xFFFACED2);

  static const Color ink = Color(0xFF0B1220);
  static const Color gray900 = Color(0xFF0B1220);
  static const Color gray800 = Color(0xFF343B47);
  static const Color gray700 = Color(0xFF4B5360);
  static const Color gray500 = Color(0xFF6B7280);
  static const Color gray400 = Color(0xFF9CA3B0);
  static const Color gray300 = Color(0xFFE0E3E9);
  static const Color gray200 = Color(0xFFE6E8EC);
  static const Color gray100 = Color(0xFFECEEF2);
  static const Color appBg = Color(0xFFF6F7F9);
  static const Color surface = Colors.white;

  static const Color success = Color(0xFF1FAE6B);
  static const Color success100 = Color(0xFFE6F6EE);
  static const Color success700 = Color(0xFF106B41);

  static const Color warning = Color(0xFFF5A524);
  static const Color warning100 = Color(0xFFFFF6E5);
  static const Color warning200 = Color(0xFFFFE5B3);
  static const Color warning700 = Color(0xFF99620C);

  static const Color alert = Color(0xFFE5484D);
  static const Color alert100 = Color(0xFFFDECEE);
  static const Color alert700 = Color(0xFF9A262A);

  static const Color info = Color(0xFF2D5BD7);
  static const Color info100 = Color(0xFFE4ECFE);

  static const LinearGradient brandWash = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: <Color>[Color(0xFFFEECEE), Color(0xFFF6F7F9)],
  );

  static const LinearGradient brandSolid = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[Color(0xFFDC1F2E), Color(0xFF8E121C)],
  );

  static const LinearGradient avatar = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[Color(0xFFDC1F2E), Color(0xFF8E121C)],
  );
}
