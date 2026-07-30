import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Who an emergency contact is to the user. Burmese-first labels for the UI.
enum ContactRelationship { family, friend, partner }

extension ContactRelationshipLabel on ContactRelationship {
  String get label {
    switch (this) {
      case ContactRelationship.family:
        return 'မိသားစု';
      case ContactRelationship.friend:
        return 'သူငယ်ချင်း';
      case ContactRelationship.partner:
        return 'ဘော်ဖရဲန်း/ဂရဲဖရဲန်း';
    }
  }
}

/// A single saved safety contact.
class EmergencyContact {
  final String id;
  final String name;
  final String phoneNumber;
  final ContactRelationship relationship;

  const EmergencyContact({
    required this.id,
    required this.name,
    required this.phoneNumber,
    required this.relationship,
  });
}

/// Result of firing the SOS alert — used to build the "location shared" toast.
class SosResult {
  final int notifiedCount;
  final String location;
  const SosResult({required this.notifiedCount, required this.location});
}

/// Immutable snapshot of the user's safety contacts.
class SafetyState {
  /// Hard cap on saved contacts (mirrors Grab/Uber's small trusted list).
  static const int maxContacts = 3;

  final List<EmergencyContact> contacts;

  const SafetyState({this.contacts = const []});

  bool get canAddMore => contacts.length < maxContacts;

  SafetyState copyWith({List<EmergencyContact>? contacts}) =>
      SafetyState(contacts: contacts ?? this.contacts);
}

/// Mock safety "service" — a Riverpod [StateNotifier], matching the repo's
/// existing state pattern (see `WalletNotifier`). No backend/network: SOS is
/// simulated. This is the seam a real SMS/location pipeline slots behind later.
class SafetyNotifier extends StateNotifier<SafetyState> {
  SafetyNotifier() : super(_seed());

  /// One demo contact so the list isn't empty, with room to add two more.
  static SafetyState _seed() => const SafetyState(
        contacts: [
          EmergencyContact(
            id: 'seed-1',
            name: 'မမြင့်မြင့်',
            phoneNumber: '09750000001',
            relationship: ContactRelationship.family,
          ),
        ],
      );

  /// Adds a contact. Returns false (and changes nothing) when the list is full
  /// or the required fields are blank.
  bool addContact(String name, String phoneNumber, ContactRelationship relationship) {
    if (!state.canAddMore) return false;
    if (name.trim().isEmpty || phoneNumber.trim().isEmpty) return false;

    final contact = EmergencyContact(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: name.trim(),
      phoneNumber: phoneNumber.trim(),
      relationship: relationship,
    );
    state = state.copyWith(contacts: [...state.contacts, contact]);
    return true;
  }

  void removeContact(String id) {
    state = state.copyWith(
      contacts: state.contacts.where((c) => c.id != id).toList(),
    );
  }

  /// Simulates broadcasting the user's live location to every saved contact by
  /// SMS. Returns how many were notified so the UI can confirm.
  SosResult triggerSOSAlert(String currentLocation) {
    // In a real build this would send an SMS/push per contact and ping the
    // safety team; here we just report what *would* happen.
    return SosResult(
      notifiedCount: state.contacts.length,
      location: currentLocation,
    );
  }
}

/// App-wide safety provider. NOT autoDispose: the contact list must persist
/// across the session regardless of which screen is showing.
final safetyProvider =
    StateNotifierProvider<SafetyNotifier, SafetyState>((ref) => SafetyNotifier());
