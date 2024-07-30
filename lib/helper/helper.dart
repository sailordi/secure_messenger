import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'dart:async';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';

class Helper {
  
  static void circleDialog(BuildContext context) {
    showDialog(context: context,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        )
    );
  }

  static void messageToUser(String str,BuildContext context) {
    showDialog(context: context,
        builder: (context) => Center(
            child: AlertDialog(
              title: Text(str),
            )
        )
    );
  }

  static String formatTimeStamp(DateTime t) {
    DateFormat formatter = DateFormat('dd-MM-yyyy HH:mm:ss');

    return formatter.format(t);
  }

  static String timestampToDb(DateTime d) {
    return d.toUtc().toString().replaceAll('-', '').replaceAll(':', '').replaceAll(' ', '').substring(0, 14);
  }

  static DateTime timestampFromDb(String d) {
    if (d.length != 14) {
      throw const FormatException("The timestamp string must be exactly 14 characters long.");
    }

    // Verify each component
    int? year = int.tryParse(d.substring(0,4));
    int? month = int.tryParse(d.substring(4,6));
    int? day = int.tryParse(d.substring(6,8));
    int? hour = int.tryParse(d.substring(8,10));
    int? minute = int.tryParse(d.substring(10,12));
    int? second = int.tryParse(d.substring(12,14));

    if (year == null || month == null || day == null || hour == null || minute == null || second == null) {
      throw const FormatException("Invalid date components in the string.");
    }

    return DateTime.utc(year, month, day, hour, minute, second);
  }

}