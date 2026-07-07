// Onboarding voice mode (spec §4.1/§4.6) — verifies the OFFLINE extractor:
//   • pulls age/gender/phone/skills from a spoken sentence (Arabic or Burmese
//     numerals), never inventing a field it can't read;
//   • constrains skills to taskers only;
//   • AiService.extractOnboarding falls back to it (no Firebase, no hang).
import 'package:flutter_test/flutter_test.dart';

import 'package:toly_moly/core/utils/ai_mock.dart';
import 'package:toly_moly/core/utils/ai_service.dart';
import 'package:toly_moly/features/onboarding/onboarding_models.dart';

void main() {
  setUp(() => AiConfig.useLiveAi = false);
  tearDown(() => AiConfig.useLiveAi = true);

  group('extractOnboardingMock', () {
    test('reads age, gender, phone, and tasker skills', () {
      final r = extractOnboardingMock(
        'ကျွန်တော် အသက် 25 နှစ်၊ ကျားပါ။ ဖုန်းက 09781234567။ '
        'သန့်ရှင်းရေးနဲ့ ပိုက်ပြင်တာ လုပ်တတ်ပါတယ်။',
        isTasker: true,
      );
      expect(r.age, 25);
      expect(r.gender, 'male');
      expect(r.phone, '09781234567');
      expect(r.skillIds, containsAll(<String>['cleaning', 'plumbing']));
      // Never invents a name it can't parse offline.
      expect(r.name, '');
    });

    test('handles Burmese numerals', () {
      final r = extractOnboardingMock('အသက် ၃၀ ၊ ဖုန်း ၀၉၄၅၆၇၈၉၀၁၂',
          isTasker: false);
      expect(r.age, 30);
      expect(r.phone, '09456789012');
    });

    test('detects female gender', () {
      final r =
          extractOnboardingMock('ကျွန်မ အမျိုးသမီးပါ', isTasker: false);
      expect(r.gender, 'female');
    });

    test('client role never gets skills', () {
      final r = extractOnboardingMock('သန့်ရှင်းရေး လုပ်တတ်ပါတယ်',
          isTasker: false);
      expect(r.skillIds, isEmpty);
    });

    test('empty / unheard input yields all-empty (no invention)', () {
      final r = extractOnboardingMock('ဟုတ်ကဲ့ ကျေးဇူးတင်ပါတယ်', isTasker: true);
      expect(r.age, isNull);
      expect(r.gender, isNull);
      expect(r.phone, '');
      expect(r.skillIds, isEmpty);
      expect(r.name, '');
    });
  });

  group('AiService.extractOnboarding (offline fallback)', () {
    test('maps primitives to enums and marks the source', () async {
      final e = await AiService.extractOnboarding(
        transcript: 'အသက် 40 ၊ ကျားပါ။ ဖုန်း 09112223334။ လျှပ်စစ် လုပ်တတ်တယ်။',
        role: UserRole.tasker,
      );
      expect(e.source, AiSource.mock);
      expect(e.age, 40);
      expect(e.gender, Gender.male);
      expect(e.phone, '09112223334');
      expect(e.skills, contains(TaskerSkill.electrical));
      expect(e.hasAnything, isTrue);
    });

    test('client role drops skills even if skill words were spoken', () async {
      final e = await AiService.extractOnboarding(
        transcript: 'ပိုက်ပြင်တာ လုပ်တတ်တယ်။ အသက် 22။',
        role: UserRole.client,
      );
      expect(e.skills, isEmpty);
      expect(e.age, 22);
    });
  });
}
