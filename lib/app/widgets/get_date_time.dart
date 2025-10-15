import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class GetDateFormat {

  // static String formatDate="dd-MM-yyyy";


  static String getCurrentDate(){
    DateTime now = DateTime.now();
    String formattedDate = DateFormat('yyyy-MM-dd HH:mm:ss').format(now);
    print('Current date and time: $formattedDate');
    return formattedDate;
  }

  static String getNextDateOfCurrentDate(){
    DateTime now = DateTime.now();
    final date = now.add(Duration(days: 1));
    String nextDate = DateFormat("yyyy-MM-dd").format(date);
    /* DateTime now = DateTime.now();
    String formattedDate = DateFormat(formatDate).format(now);*/
    print('Next date of current date is $nextDate');
    return nextDate;

  }

  static String getNextMonthDateOfCurrentDate(){
    DateTime now = DateTime.now();
    final date = now.add(Duration(days: 30));
    String nextDate = DateFormat("yyyy-MM-dd").format(date);
    /* DateTime now = DateTime.now();
    String formattedDate = DateFormat(formatDate).format(now);*/
    print('Next date of current date is $nextDate');
    return nextDate;

  }
  static String getFormatedDate(DateTime dateTime){
    DateTime now = dateTime;
    String formattedDate = DateFormat("yyyy-MM-dd").format(now);
    print('the format is $formattedDate');
    return formattedDate;

  }







}