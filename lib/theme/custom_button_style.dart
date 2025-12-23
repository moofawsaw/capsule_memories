import 'package:flutter/material.dart';

// ... keep existing code ...

  ButtonStyle get fillDestructive => ElevatedButton.styleFrom(
        backgroundColor: ThemeData().colorScheme.error,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 0,
        padding: EdgeInsets.zero,
      );

// ... rest of code ...