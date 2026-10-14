import 'package:flutter_test/flutter_test.dart';
import 'package:greenyuva/models/green_commute_data.dart';
import 'package:greenyuva/models/quiz.dart';

GreenCommuteData _data(int steps) => GreenCommuteData(
      stepsToday: steps,
      streakDays: 1,
      lastActiveDate: DateTime(2026, 1, 1),
      claimedKarmaCoins: 0,
      isInsideCampus: true,
      distanceFromCampusMeters: 0,
      campusName: 'Test',
    );

void main() {
  group('GreenCommuteData', () {
    test('petrol saved assumes 35 km/L', () {
      // 1500 steps = 1 km -> 1/35 L
      expect(_data(1500).petrolSavedLiters, closeTo(1 / 35, 1e-9));
    });

    test('unclaimed karma never negative', () {
      expect(_data(0).unclaimedKarma, 0);
      expect(_data(1000).unclaimedKarma, 2);
    });
  });

  group('QuizQuestion.fromJson', () {
    test('accepts double points and loosely typed nested maps', () {
      final q = QuizQuestion.fromJson({
        'id': 1,
        'question': 'Q?',
        'points': 10.0,
        'correctAnswerId': 'a',
        'answers': [
          <Object?, Object?>{'id': 'a', 'text': 'Yes', 'isCorrect': true},
        ],
      });
      expect(q.points, 10);
      expect(q.id, '1');
      expect(q.answers.single.isCorrect, isTrue);
    });

    test('tolerates missing fields', () {
      final q = QuizQuestion.fromJson({});
      expect(q.answers, isEmpty);
      expect(q.points, 0);
    });
  });
}
