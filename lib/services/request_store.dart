/// In-memory store for AidBridge.
/// Used for optimistic UI updates and local state before Firestore confirms.
library request_store;

class AidRequest {
  final String id;
  final String title;
  final String description;
  final String category;
  final String location;
  final int volunteersNeeded;
  final bool needsDonation;
  final bool needsVolunteers;
  final String status; // 'open' | 'fulfilled' | 'closed'
  final String postedBy;

  const AidRequest({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.location,
    required this.volunteersNeeded,
    required this.needsDonation,
    required this.needsVolunteers,
    required this.status,
    required this.postedBy,
  });

  AidRequest copyWith({String? status}) => AidRequest(
        id: id,
        title: title,
        description: description,
        category: category,
        location: location,
        volunteersNeeded: volunteersNeeded,
        needsDonation: needsDonation,
        needsVolunteers: needsVolunteers,
        status: status ?? this.status,
        postedBy: postedBy,
      );
}

class DonationOffer {
  final String requestId;
  final String donorName;
  final String donationType; // 'monetary' | 'goods' | 'food' | 'clothing' | 'other'
  final double amount;
  final String note;
  final String status; // 'pending' | 'accepted' | 'rejected'

  const DonationOffer({
    required this.requestId,
    required this.donorName,
    required this.donationType,
    required this.amount,
    required this.note,
    required this.status,
  });

  DonationOffer copyWith({String? status}) => DonationOffer(
        requestId: requestId,
        donorName: donorName,
        donationType: donationType,
        amount: amount,
        note: note,
        status: status ?? this.status,
      );
}

class VolunteerOffer {
  final String requestId;
  final String volunteerName;
  final String message;
  final String status; // 'pending' | 'accepted' | 'rejected'

  const VolunteerOffer({
    required this.requestId,
    required this.volunteerName,
    required this.message,
    required this.status,
  });

  VolunteerOffer copyWith({String? status}) => VolunteerOffer(
        requestId: requestId,
        volunteerName: volunteerName,
        message: message,
        status: status ?? this.status,
      );
}

class RequestStore {
  RequestStore._();
  static final instance = RequestStore._();

  final List<AidRequest> _requests = [];
  final List<DonationOffer> _donationOffers = [];
  final List<VolunteerOffer> _volunteerOffers = [];

  List<AidRequest> get requests => List.unmodifiable(_requests);
  List<DonationOffer> get donationOffers =>
      List.unmodifiable(_donationOffers);
  List<VolunteerOffer> get volunteerOffers =>
      List.unmodifiable(_volunteerOffers);

  // --- Requests ---
  void addRequest(AidRequest req) => _requests.insert(0, req);

  void updateRequestStatus(String id, String status) {
    final idx = _requests.indexWhere((r) => r.id == id);
    if (idx != -1) _requests[idx] = _requests[idx].copyWith(status: status);
  }

  // --- Donation Offers ---
  void addDonationOffer(DonationOffer offer) =>
      _donationOffers.insert(0, offer);

  void updateDonationOfferStatus(String requestId, String status) {
    final idx =
        _donationOffers.indexWhere((o) => o.requestId == requestId);
    if (idx != -1) {
      _donationOffers[idx] = _donationOffers[idx].copyWith(status: status);
    }
  }

  // --- Volunteer Offers ---
  void addVolunteerOffer(VolunteerOffer offer) =>
      _volunteerOffers.insert(0, offer);

  void updateVolunteerOfferStatus(String requestId, String status) {
    final idx =
        _volunteerOffers.indexWhere((o) => o.requestId == requestId);
    if (idx != -1) {
      _volunteerOffers[idx] =
          _volunteerOffers[idx].copyWith(status: status);
    }
  }

  /// Clear all data (e.g. on sign-out)
  void clear() {
    _requests.clear();
    _donationOffers.clear();
    _volunteerOffers.clear();
  }
}