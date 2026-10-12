import 'package:flutter/material.dart';

/// Consistent forward/back motion for routes wholly within the companion flow.
class CompanionRoute<T> extends PageRouteBuilder<T> {
  CompanionRoute({
    required BuildContext context,
    required WidgetBuilder builder,
    super.settings,
  }) : super(
         transitionDuration: MediaQuery.of(context).disableAnimations
             ? Duration.zero
             : const Duration(milliseconds: 260),
         reverseTransitionDuration: MediaQuery.of(context).disableAnimations
             ? Duration.zero
             : const Duration(milliseconds: 240),
         pageBuilder: (context, _, _) => builder(context),
         transitionsBuilder: (context, animation, _, child) {
           if (MediaQuery.of(context).disableAnimations) return child;
           final curved = CurvedAnimation(
             parent: animation,
             curve: Curves.easeOutCubic,
             reverseCurve: Curves.easeInCubic,
           );
           return FadeTransition(
             opacity: curved,
             child: SlideTransition(
               position: Tween<Offset>(
                 begin: const Offset(0.05, 0),
                 end: Offset.zero,
               ).animate(curved),
               child: child,
             ),
           );
         },
       );
}
