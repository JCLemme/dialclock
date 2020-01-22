// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Dialclock by John Lemme, 2020

import 'dart:async';
import 'dart:core';

import 'package:flutter/services.dart';
import 'package:flutter_clock_helper/model.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flare_flutter/flare_actor.dart';

import 'dial_controller.dart';

enum _Element {
  background,
  dialHourFirst,
  dialHourSecond,
  dialMinuteFirst,
  dialMinuteSecond,
  dialText,
}

final _lightTheme = {
  _Element.background: Colors.white,
  _Element.dialHourFirst: Colors.red,
  _Element.dialHourSecond: Colors.yellow,
  _Element.dialMinuteFirst: Colors.blue,
  _Element.dialMinuteSecond: Colors.green,
  _Element.dialText: Colors.black,
};

final _darkTheme = {
  _Element.background: Colors.black,
  _Element.dialHourFirst: Colors.red,
  _Element.dialHourSecond: Colors.yellow,
  _Element.dialMinuteFirst: Colors.blue,
  _Element.dialMinuteSecond: Colors.green,
  _Element.dialText: Colors.white,
};

class DigitalClock extends StatefulWidget {
  const DigitalClock(this.model);

  final ClockModel model;

  @override
  _DigitalClockState createState() => _DigitalClockState();
}

class _DigitalClockState extends State<DigitalClock> {
  DateTime _dateTime = DateTime.now();
  Timer _timer;

  List<DialController> _dialControllers = [
    new DialController(color: _lightTheme[_Element.dialHourFirst], angle: 200),
    new DialController(color: _lightTheme[_Element.dialHourSecond], angle: 315),
    new DialController(color: _lightTheme[_Element.dialMinuteFirst], angle: 50),
    new DialController(color: _lightTheme[_Element.dialMinuteSecond]),
  ];

  @override
  void initState() {
    super.initState();
    widget.model.addListener(_updateModel);
    _updateTime();
    _updateModel();
  }

  @override
  void didUpdateWidget(DigitalClock oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.model != oldWidget.model) {
      oldWidget.model.removeListener(_updateModel);
      widget.model.addListener(_updateModel);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    widget.model.removeListener(_updateModel);
    widget.model.dispose();
    super.dispose();
  }

  void _updateModel() {
    setState(() {
      // Cause the clock to rebuild when the model changes.
    });
  }

  void _updateTime() {
    setState(() {
      // Update the time and schedule the next update.
      _dateTime = DateTime.now();

      // Schedules a millisecond ahead to ensure we update in time
      _timer = Timer(
        Duration(minutes: 1) -
            Duration(seconds: _dateTime.second) -
            Duration(milliseconds: _dateTime.millisecond),
        _updateTime,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).brightness == Brightness.light
        ? _lightTheme
        : _lightTheme; // Quick disable dark theme
    final hour =
        DateFormat(widget.model.is24HourFormat ? 'HH' : 'hh').format(_dateTime);
    final minute = DateFormat('mm').format(_dateTime);

    // Set dials to current colors
    _dialControllers[0].setColorScheme(
        colors[_Element.dialHourFirst], colors[_Element.dialText]);
    _dialControllers[1].setColorScheme(
        colors[_Element.dialHourSecond], colors[_Element.dialText]);
    _dialControllers[2].setColorScheme(
        colors[_Element.dialMinuteFirst], colors[_Element.dialText]);
    _dialControllers[3].setColorScheme(
        colors[_Element.dialMinuteSecond], colors[_Element.dialText]);

    // Set dials to the current time
    _dialControllers[1].setValue((int.parse(hour) / 10).floor());
    _dialControllers[0].setValue(int.parse(hour) % 10);
    _dialControllers[2].setValue((int.parse(minute) / 10).floor());
    _dialControllers[3].setValue(int.parse(minute) % 10);

    final double _ringSize = MediaQuery.of(context).size.height * 3;

    return Container(
      color: colors[_Element.background],
      child: Stack(
        children: <Widget>[
          Positioned(
              // BLUE
              width: _ringSize,
              height: _ringSize,
              top: 100 - (_ringSize / 2),
              right: 130 - (_ringSize / 2),
              child: FlareActor("third_party/hatena_pivot.flr",
                  fit: BoxFit.contain, controller: _dialControllers[2])),
          Positioned(
              // GREEN
              width: _ringSize,
              height: _ringSize,
              top: 100 - (_ringSize / 2),
              right: 50 - (_ringSize / 2),
              child: FlareActor("third_party/hatena_pivot.flr",
                  fit: BoxFit.contain, controller: _dialControllers[3])),
          Positioned(
              // YELLOW
              width: _ringSize * 1.5,
              height: _ringSize * 1.5,
              top: 100 - (_ringSize * 1.5 / 2),
              right: 380 - (_ringSize * 1.5 / 2),
              child: FlareActor("third_party/hatena_pivot.flr",
                  fit: BoxFit.contain, controller: _dialControllers[1])),
          Positioned(
              // RED
              width: _ringSize * 1.5,
              height: _ringSize * 1.5,
              top: 100 - (_ringSize * 1.5 / 2),
              right: 250 - (_ringSize * 1.5 / 2),
              child: FlareActor("third_party/hatena_pivot.flr",
                  fit: BoxFit.contain, controller: _dialControllers[0])),
        ],
      ),
    );
  }
}
