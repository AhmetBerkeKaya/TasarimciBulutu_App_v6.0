// lib/data/models/skill_test.dart
import 'dart:convert';

class SkillTest {
  final String id;
  final String title;
  final String? description;
  final String software;
  final List<Question>? questions; // Detay görünümünde dolu olacak

  SkillTest({
    required this.id,
    required this.title,
    this.description,
    required this.software,
    this.questions,
  });

  factory SkillTest.fromJson(Map<String, dynamic> json) {
    return SkillTest(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      software: json['software'],
      questions: json['questions'] != null
          ? List<Question>.from(json['questions'].map((x) => Question.fromJson(x)))
          : null,
    );
  }
}

class Question {
  final String id;
  final String questionText;
  final List<Choice> choices;

  Question({
    required this.id,
    required this.questionText,
    required this.choices,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['id'],
      questionText: json['question_text'],
      choices: List<Choice>.from(json['choices'].map((x) => Choice.fromJson(x))),
    );
  }
}

class Choice {
  final String id;
  final String choiceText;

  Choice({
    required this.id,
    required this.choiceText,
  });

  factory Choice.fromJson(Map<String, dynamic> json) {
    return Choice(
      id: json['id'],
      choiceText: json['choice_text'],
    );
  }
}