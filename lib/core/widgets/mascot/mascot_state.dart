/// The supported visual states for TOLY MOLY's Pho Wa Yoke mascot.
///
/// Keep mascot asset paths here so feature screens never depend on the
/// underlying PNG implementation.
enum PhoWaYokeState {
  idle,
  happy,
  thinking,
  pointing,
  success,
}

extension PhoWaYokeStateAsset on PhoWaYokeState {
  String get assetPath {
    switch (this) {
      case PhoWaYokeState.idle:
        return 'assets/mascot/pho_wa_yoke_idle.png';
      case PhoWaYokeState.happy:
        return 'assets/mascot/pho_wa_yoke_happy.png';
      case PhoWaYokeState.thinking:
        return 'assets/mascot/pho_wa_yoke_thinking.png';
      case PhoWaYokeState.pointing:
        return 'assets/mascot/pho_wa_yoke_pointing.png';
      case PhoWaYokeState.success:
        return 'assets/mascot/pho_wa_yoke_success.png';
    }
  }

  String get semanticLabel {
    switch (this) {
      case PhoWaYokeState.idle:
        return 'Pho Wa Yoke ready to help';
      case PhoWaYokeState.happy:
        return 'Pho Wa Yoke welcoming you';
      case PhoWaYokeState.thinking:
        return 'Pho Wa Yoke thinking';
      case PhoWaYokeState.pointing:
        return 'Pho Wa Yoke showing the next step';
      case PhoWaYokeState.success:
        return 'Pho Wa Yoke celebrating success';
    }
  }
}
