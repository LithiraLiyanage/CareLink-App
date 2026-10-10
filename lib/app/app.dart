import 'package:flutter/material.dart';

import '../features/auth/screens/splash_screen.dart';
import '../features/auth/services/accessibility_controller.dart';
import 'theme.dart';

class CareLinkApp extends StatelessWidget {
  const CareLinkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AccessibilityPreferences>(
      valueListenable: AccessibilityController.instance,
      builder: (context, preferences, _) {
        final baseTheme = preferences.highContrast
            ? CareLinkTheme.highContrastTheme
            : CareLinkTheme.lightTheme;
        return MaterialApp(
          title: 'CareLink',
          debugShowCheckedModeBanner: false,
          theme: preferences.reduceMotion
              ? baseTheme.copyWith(
                  pageTransitionsTheme: PageTransitionsTheme(
                    builders: {
                      for (final platform in TargetPlatform.values)
                        platform: const _NoMotionPageTransitionsBuilder(),
                    },
                  ),
                )
              : baseTheme,
          themeAnimationDuration: preferences.reduceMotion
              ? Duration.zero
              : const Duration(milliseconds: 200),
          builder: (context, child) {
            final mediaQuery = MediaQuery.of(context);
            Widget content = MediaQuery(
              data: mediaQuery.copyWith(
                textScaler: preferences.largerText
                    ? mediaQuery.textScaler.clamp(minScaleFactor: 1.2)
                    : mediaQuery.textScaler,
                disableAnimations:
                    mediaQuery.disableAnimations || preferences.reduceMotion,
              ),
              child: child ?? const SizedBox.shrink(),
            );

            if (preferences.highContrast) {
              content = ColorFiltered(
                colorFilter: const ColorFilter.matrix(<double>[
                  1.5,
                  0,
                  0,
                  0,
                  -100,
                  0,
                  1.5,
                  0,
                  0,
                  -100,
                  0,
                  0,
                  1.5,
                  0,
                  -100,
                  0,
                  0,
                  0,
                  1,
                  0,
                ]),
                child: content,
              );
            }
            return content;
          },
          home: const SplashScreen(),
        );
      },
    );
  }
}

class _NoMotionPageTransitionsBuilder extends PageTransitionsBuilder {
  const _NoMotionPageTransitionsBuilder();

  @override
  Duration get transitionDuration => Duration.zero;

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => child;
}
