class SystemVoice {
  const SystemVoice({
    required this.id,
    required this.name,
    required this.locale,
    this.quality = '',
    this.gender = '',
    this.networkRequired = false,
  });
  final String id;
  final String name;
  final String locale;
  final String quality;
  final String gender;
  final bool networkRequired;
  String get qualityLabel =>
      quality.toLowerCase().contains('premium') ||
          quality.toLowerCase() == 'very high'
      ? '최고 품질'
      : quality.toLowerCase().contains('enhanced') ||
            quality.toLowerCase() == 'high'
      ? '고품질'
      : '기본 품질';
  int get qualityRank => qualityLabel == '최고 품질'
      ? 2
      : qualityLabel == '고품질'
      ? 1
      : 0;
  String get detail => [
    if (gender.toLowerCase() == 'male') '남성',
    if (gender.toLowerCase() == 'female') '여성',
    qualityLabel,
    if (networkRequired) '인터넷 필요',
  ].join(' · ');
  Map<String, String> get native => {
    'identifier': id,
    'name': name,
    'locale': locale,
  };
}

String koreanCount(int value) {
  if (value <= 0) return '영';
  if (value > 9999) return '$value';
  const ones = ['', '하나', '둘', '셋', '넷', '다섯', '여섯', '일곱', '여덟', '아홉'];
  const tens = ['', '열', '스물', '서른', '마흔', '쉰', '예순', '일흔', '여든', '아흔'];
  const sino = ['', '일', '이', '삼', '사', '오', '육', '칠', '팔', '구'];
  var prefix = '';
  final thousands = value ~/ 1000;
  final hundreds = (value % 1000) ~/ 100;
  if (thousands > 0) prefix += '${thousands == 1 ? '' : sino[thousands]}천';
  if (hundreds > 0) prefix += '${hundreds == 1 ? '' : sino[hundreds]}백';
  return '$prefix${tens[(value % 100) ~/ 10]}${ones[value % 10]}';
}
