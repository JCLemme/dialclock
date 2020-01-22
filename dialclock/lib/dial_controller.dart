// Dialclock by John Lemme, 2020

import 'dart:core';

import 'package:flutter/material.dart';
import 'package:flare_flutter/flare.dart';
import 'package:flare_flutter/flare_controller.dart';
import 'package:flare_dart/math/mat2d.dart';
import 'package:vector_math/vector_math.dart' as VectorMath;
import 'dart:math';

class DialController extends FlareController {
  ActorAnimation _spin;
  double _duration = 0.0, _angle = 0;
  int _next = 0;
  bool _shouldUpdate = false;
  Color _maskColor = Colors.white, _fontColor = Colors.black;

  DialController({Color color = Colors.white, double angle = 0}) {
    _maskColor = color;
    _angle = angle;
  }

  // Displays a given digit, 0-9
  void setValue(int next) {
    // If the digit is actually different, schedule an update
    if (_next != next % 10) {
      // Set the new value, reset the clock, and tell the animation to reset
      _next = next % 10;
      _duration = 0;
      _shouldUpdate = true;
      this.isActive.value = true;
    }
  }

  // Sets the color of the dial and text
  void setColorScheme(Color dialColor, Color textColor) {
    if (dialColor != _maskColor) {
      _maskColor = dialColor;
      _shouldUpdate = true;
    }

    if (textColor != _fontColor) {
      _fontColor = textColor;
      _shouldUpdate = true;
    }
  }

  void initialize(FlutterActorArtboard artboard) {
    // Grab animation handle
    _spin = artboard.getAnimation("spin");

    // Set spinner color
    FlutterActorShape _maskNode = artboard.getNode("color");
    FlutterColorFill _maskFill = _maskNode?.fill as FlutterColorFill;
    _maskFill.uiColor = _maskColor;

    // Set rotation values. Keeps the number perpendicular to the ground
    artboard.getNode("indicator").rotation = VectorMath.radians(_angle);
    artboard.getNode("numbers").rotation = VectorMath.radians(-_angle);

    // Cheat the ring bigger at different angles, to account for digit sizes.
    // This won't work very well at steep angles (90 and 270, in particular)
    // but it's fine for how we're using the display

    final _setScale = (node, start, modifier) {
      artboard.getNode(node).scaleX =
          start + (modifier * sin(VectorMath.radians(_angle) * 2).abs());
    };

    // Outside ring.
    _setScale("c_out", 1, 0.05);
    _setScale("m_out", 1, 0.05);

    // Inside ring. Needs to change a little more
    _setScale("c_in", 1.25, -0.07);
    _setScale("m_in", 1.25, -0.07);

    // Show a zero as a placeholder
    for (int _digit = 0; _digit < 10; _digit++) {
      FlutterActorShape _fontNode =
          artboard.getNode("num_" + _digit.toString());
      _fontNode.opacity = (_digit == 0) ? 1 : 0;

      FlutterColorFill _fontFill = _fontNode?.fill as FlutterColorFill;
      _fontFill.uiColor = _fontColor;
    }
  }

  void setViewTransform(Mat2D viewTransform) {}

  bool advance(FlutterActorArtboard artboard, double elapsed) {
    // Time marches forward
    _duration += elapsed;

    // If the animation should still be playing...
    if (_duration < _spin.duration) {
      // ...apply the animation to the artboard
      _spin.apply(_duration, artboard, 1.0);

      // When we're halfway through, check to see if we need to change the digit
      if ((_duration >= _spin.duration / 2) && _shouldUpdate) {
        // Update dial color if need be
        FlutterActorShape _maskNode = artboard.getNode("color");
        FlutterColorFill _maskFill = _maskNode?.fill as FlutterColorFill;
        _maskFill.uiColor = _maskColor;

        // Make the desired digit visible, and make sure everything else is invisible!
        for (int _digit = 0; _digit < 10; _digit++) {
          FlutterActorShape _fontNode =
              artboard.getNode("num_" + _digit.toString());
          _fontNode.opacity = (_digit == _next) ? 1 : 0;

          FlutterColorFill _fontFill = _fontNode?.fill as FlutterColorFill;
          _fontFill.uiColor = _fontColor;
        }

        _shouldUpdate = false;
      }
    } else {
      return false;
    }

    return true;
  }
}
