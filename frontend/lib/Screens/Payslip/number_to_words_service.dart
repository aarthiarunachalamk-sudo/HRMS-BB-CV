class NumberToWordsService {
  static const _ones = [
    '',
    'One',
    'Two',
    'Three',
    'Four',
    'Five',
    'Six',
    'Seven',
    'Eight',
    'Nine',
    'Ten',
    'Eleven',
    'Twelve',
    'Thirteen',
    'Fourteen',
    'Fifteen',
    'Sixteen',
    'Seventeen',
    'Eighteen',
    'Nineteen',
  ];

  static const _tens = [
    '',
    '',
    'Twenty',
    'Thirty',
    'Forty',
    'Fifty',
    'Sixty',
    'Seventy',
    'Eighty',
    'Ninety',
  ];

  String rupees(num value) {
    final amount = value.round();
    if (amount == 0) return 'Zero Rupees Only';
    return '${_convert(amount)} Rupees Only';
  }

  String _convert(int number) {
    if (number < 20) return _ones[number];
    if (number < 100) {
      return '${_tens[number ~/ 10]} ${_ones[number % 10]}'.trim();
    }
    if (number < 1000) {
      return '${_ones[number ~/ 100]} Hundred ${_convert(number % 100)}'.trim();
    }
    if (number < 100000) {
      return '${_convert(number ~/ 1000)} Thousand ${_convert(number % 1000)}'.trim();
    }
    if (number < 10000000) {
      return '${_convert(number ~/ 100000)} Lakh ${_convert(number % 100000)}'.trim();
    }
    return '${_convert(number ~/ 10000000)} Crore ${_convert(number % 10000000)}'.trim();
  }
}
