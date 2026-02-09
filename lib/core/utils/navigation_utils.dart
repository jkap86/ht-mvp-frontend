import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Navigates back if possible, otherwise goes to the fallback route.
void navigateBack(BuildContext context, {String fallback = '/'}) {
  if (context.canPop()) {
    context.pop();
  } else {
    context.go(fallback);
  }
}
