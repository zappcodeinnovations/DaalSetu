import '../../../shared/view/offer_interest_negotiation_chat_view.dart';

/// Seller wrapper for the exact same ProductInterest chat used by buyers.
class SellerInterestThreadView extends OfferInterestNegotiationChatView {
  const SellerInterestThreadView({
    super.key,
    required super.productId,
    required super.interestId,
  }) : super(isBuyer: false);
}
