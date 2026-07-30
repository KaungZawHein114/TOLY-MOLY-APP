// Onboarding voice mode — verifies the offline extractor helper:
//   • pulls age/gender/phone/skills from a spoken sentence (Arabic or Burmese
//     numerals), never inventing a field it can't read;
//   • constrains skills to taskers only.
//
// NOTE: this extractor is no longer called by anything in the app —
// the onboarding voice-auth flow (voice_onboarding_sheet.dart) was rewritten
// to a fixed demo idle→listening→processing→verified sequence in an earlier
// session, and AiService.extractOnboarding (the Firebase-calling wrapper
// around this function) was deleted outright during the Firebase-removal
// refactor since it had zero remaining callers. extractOnboardingMock itself
// stays — it's a plain, useful offline text-extraction utility — but these
// tests now exercise it directly rather than through AiService.
import 'package:flutter_test/flutter_test.dart';

import 'package:toly_moly/core/utils/ai_mock.dart';

void main() {
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
}
