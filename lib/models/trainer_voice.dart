enum TrainerVoice {
  male('male_trainer', '남성 트레이너', '묵직하고 또렷한 카운팅'),
  female('female_trainer', '여성 트레이너', '밝고 힘 있는 카운팅');

  const TrainerVoice(this.id, this.label, this.description);
  final String id;
  final String label;
  final String description;
}
