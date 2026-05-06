class AmountToWords {
  static const _units = ['', 'un', 'deux', 'trois', 'quatre', 'cinq', 'six', 'sept', 'huit', 'neuf'];
  static const _teens = ['dix', 'onze', 'douze', 'treize', 'quatorze', 'quinze', 'seize', 'dix-sept', 'dix-huit', 'dix-neuf'];
  static const _tens = ['', 'dix', 'vingt', 'trente', 'quarante', 'cinquante', 'soixante', 'soixante', 'quatre-vingt', 'quatre-vingt'];

  static String convert(double amount) {
    final intPart = amount.truncate();
    final decimalPart = ((amount - intPart) * 100).round();

    String result = _convertInt(intPart);

    if (decimalPart > 0) {
      result += ' et $decimalPart/100';
    }

    return result;
  }

  static String _convertInt(int number) {
    if (number == 0) return 'zéro';

    final parts = <String>[];

    if (number >= 1000000) {
      final millions = number ~/ 1000000;
      parts.add('${_convertHundreds(millions)} million${millions > 1 ? 's' : ''}');
      number %= 1000000;
    }

    if (number >= 1000) {
      final thousands = number ~/ 1000;
      if (thousands == 1) {
        parts.add('mille');
      } else {
        parts.add('${_convertHundreds(thousands)} mille');
      }
      number %= 1000;
    }

    if (number > 0) {
      parts.add(_convertHundreds(number));
    }

    return parts.join(' ');
  }

  static String _convertHundreds(int number) {
    if (number == 0) return '';

    final parts = <String>[];

    final hundreds = number ~/ 100;
    final remainder = number % 100;

    if (hundreds > 0) {
      if (hundreds == 1) {
        parts.add('cent');
      } else {
        parts.add('${_units[hundreds]} cent${remainder == 0 ? 's' : ''}');
      }
    }

    if (remainder > 0) {
      parts.add(_convertTens(remainder));
    }

    return parts.join(' ');
  }

  static String _convertTens(int number) {
    if (number < 10) return _units[number];
    if (number < 20) return _teens[number - 10];

    final ten = number ~/ 10;
    final unit = number % 10;

    if (ten == 7 || ten == 9) {
      if (unit == 1 && ten == 7) return 'soixante et onze';
      return '${_tens[ten]}-${_teens[unit]}';
    }

    if (unit == 0) return _tens[ten];
    if (unit == 1 && (ten == 8)) return '${_tens[ten]}-un';
    if (unit == 1) return '${_tens[ten]} et un';

    return '${_tens[ten]}-${_units[unit]}';
  }

  static String withCurrency(double amount, {String currency = 'dirhams'}) {
    final words = convert(amount);
    return '$words $currency';
  }
}
