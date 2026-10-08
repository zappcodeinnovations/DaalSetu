import 'package:flutter/material.dart';

import '../../../shared/view/offer_interest_negotiation_chat_view.dart';
import '../model/buyer_offer_model.dart';

/// Buyer wrapper for the shared seller-offer interest chat.
class BuyerNegotiationView extends StatelessWidget {
  final BuyerOfferModel offer;

  const BuyerNegotiationView({super.key, required this.offer});

  @override
  Widget build(BuildContext context) {
    final productId = offer.productId ?? offer.id ?? 0;
    final interestId = offer.interestId ?? offer.id ?? 0;
    if (productId <= 0 || interestId <= 0) {
      return const Scaffold(
        body: Center(child: Text('Negotiation is unavailable for this offer.')),
      );
    }
    return OfferInterestNegotiationChatView(
      productId: productId,
      interestId: interestId,
      isBuyer: true,
    );
  }
}
