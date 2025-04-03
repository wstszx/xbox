import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:xbox_remote_play/key_code.dart';
import 'package:xbox_remote_play/xbox/input_key.dart';

import 'channel_base.dart';
import "../xbox/input_frame.dart";

import '../xbox/x_cloud_client.dart';

class InputChannel extends ChannelBase {
  Queue<InputFrame> inputStates = Queue<InputFrame>();
  InputFrame lastInputState = InputFrame();

  InputChannel(XCloudClient client, String clientName)
      : super(client, clientName);

  int lx = 0;
  int ly = 0;
  int rx = 0;
  int ry = 0;

  bool aState = false;
  bool wState = false;
  bool dState = false;
  bool sState = false;

  bool jState = false;
  bool iState = false;
  bool lState = false;
  bool kState = false;

  int inputSequenceNum = 0;

  void onKey(int keycode, bool state) {
    var inputState = lastInputState.DeepCopy();

    switch (keycode) {
      case Keycode.a:
        aState = state;
        inputState = updateLeftStickAxis(inputState);
        break;
      case Keycode.w:
        wState = state;
        inputState = updateLeftStickAxis(inputState);
        break;
      case Keycode.d:
        dState = state;
        inputState = updateLeftStickAxis(inputState);
        break;
      case Keycode.s:
        sState = state;
        inputState = updateLeftStickAxis(inputState);
        break;
      case Keycode.j:
        jState = state;
        inputState = updateRightStickAxis(inputState);
        break;
      case Keycode.i:
        iState = state;
        inputState = updateRightStickAxis(inputState);
        break;
      case Keycode.l:
        lState = state;
        inputState = updateRightStickAxis(inputState);
        break;
      case Keycode.k:
        kState = state;
        inputState = updateRightStickAxis(inputState);
        break;
      case Keycode.left:
        inputState.dPadLeft = state;
        break;
      case Keycode.up:
        inputState.dPadUp = state;
        break;
      case Keycode.right:
        inputState.dPadRight = state;
        break;
      case Keycode.down:
        inputState.dPadDown = state;
        break;
      case Keycode.decimal:
      case Keycode.enter:
        inputState.a = state;
        break;
      case Keycode.escape:
        inputState.b = state;
        break;
      case Keycode.x:
        inputState.x = state;
        break;
      case Keycode.y:
        inputState.y = state;
        break;
      case Keycode.f1:
        inputState.nexus = state;
        break;
      case Keycode.f2:
        inputState.view = state;
        break;
      case Keycode.f3:
        inputState.menu = state;
        break;
      case Keycode.f:
        inputState.leftThumb = state;
        break;
      case Keycode.h:
        inputState.rightThumb = state;
        break;
      case Keycode.q:
      case Keycode.o:
        inputState.leftTrigger = state ? 65535 : 0;
        break;
      case Keycode.e:
      case Keycode.p:
        inputState.rightTrigger = state ? 65535 : 0;
        break;
      case Keycode.number1:
        inputState.leftShoulder = state;
        break;
      case Keycode.number3:
        inputState.rightShoulder = state;
        break;
      case Keycode.number7:
        inputState.leftShoulder = state;
        break;
      case Keycode.number9:
        inputState.rightShoulder = state;
        break;
      case Keycode.subtract:
        inputState.rightStickXAxis = state ? -15000 : 0;
        break;
      case Keycode.add:
        inputState.rightStickXAxis = state ? 15000 : 0;
        break;
    }
    lastInputState = inputState.DeepCopy();
    inputStates.add(inputState);
  }

  InputFrame updateLeftStickAxis(InputFrame inputState) {
    var x = 0;
    var y = 0;
    if (this.aState && this.wState) {
      x = -24575;
      y = 24575;
    } else if (this.aState && this.sState) {
      x = -24575;
      y = -24575;
    } else if (this.wState && this.dState) {
      x = 24575;
      y = 24575;
    } else if (this.dState && this.sState) {
      x = 24575;
      y = -24575;
    } else if (this.aState) {
      x = -32767;
      y = 0;
    } else if (this.wState) {
      x = 0;
      y = 32767;
    } else if (this.dState) {
      x = 32767;
      y = 0;
    } else if (this.sState) {
      y = -32767;
    }

    inputState.leftStickXAxis = x;
    inputState.leftStickYAxis = y;

    return inputState;
  }

  InputFrame updateRightStickAxis(InputFrame inputState) {
    var x = 0;
    var y = 0;
    if (this.jState && this.iState) {
      x = -24575;
      y = 24575;
    } else if (this.jState && this.kState) {
      x = -24575;
      y = -24575;
    } else if (this.iState && this.lState) {
      x = 24575;
      y = 24575;
    } else if (this.lState && this.kState) {
      x = 24575;
      y = -24575;
    } else if (this.jState) {
      x = -32767;
      y = 0;
    } else if (this.iState) {
      inputState.leftStickXAxis = 0;
      x = 0;
      y = 32767;
    } else if (this.lState) {
      x = 32767;
      y = 0;
    } else if (this.kState) {
      x = 0;
      y = -32767;
    }

    inputState.rightStickXAxis = x;
    inputState.rightStickYAxis = y;

    return inputState;
  }

  bool isRunning = true;

  Future<void> start() async {
    var startReport = ByteData(14);
    startReport.setUint8(0, 8);
    startReport.setUint32(1, inputSequenceNum, Endian.little);
    startReport.setFloat64(
        5, DateTime.now().millisecondsSinceEpoch.toDouble(), Endian.little);
    startReport.setUint8(13, 0);
    this.sendData(startReport.buffer.asUint8List());

    var receiver = this.client.transceiver.receiver;
    var lastTimestamp = 0.0;

    Future(() async {
      while (true) {
        await Future.delayed(const Duration(milliseconds: 33));
        var frameInfos = await receiver.getStats();
        var _frameInfos = Queue<StatsReport>();
        for (var info in frameInfos) {
          if (info.type == "track" && info.timestamp > lastTimestamp) {
            lastTimestamp = info.timestamp;
            _frameInfos.add(info);
          }
        }
        var packet = _createPacket(_frameInfos);
        await this.sendData(packet);
        frameInfos.clear();
        _frameInfos.clear();
      }
    });

    // var isDown = false;
    // Future.doWhile(() async {
    //   var keycode = isDown ? Keycode.down : Keycode.up;
    //   this.onKey(keycode, true);
    //   await  Future.delayed(const Duration(milliseconds: 100));
    //   this.onKey(keycode, false);
    //   isDown = !isDown;
    //   await  Future.delayed(const Duration(milliseconds: 5000));
    //   return isRunning;
    // });

    // Future.sync(() async {
    //   await Future.delayed(Duration(milliseconds: 1000));
    //   this.inputstate.Click(InputKey.nexus, 100);
    //   await Future.delayed(Duration(milliseconds: 2000));
    //   this.inputstate.Click(InputKey.nexus, 100);
    // });
  }

  Uint8List _createPacket(Queue<StatsReport> frameInfos) {
    inputSequenceNum++;
    var packetTimeNow = DateTime.now().millisecondsSinceEpoch;
    var reportType = 0;
    var totalSize = 13;

    if (frameInfos.length > 0) {
      reportType |= 1;
      totalSize += 1 + 28 * frameInfos.length;
    }

    if (inputStates.length > 0) {
      reportType |= 2;
      totalSize += 1 + (23 * inputStates.length);
    }

    var metadataReport = ByteData(totalSize);

    metadataReport.setUint8(0, reportType);
    metadataReport.setUint32(1, inputSequenceNum, Endian.little);
    metadataReport.setFloat64(5, packetTimeNow.toDouble(), Endian.little);

    var offset = 13;

    if (frameInfos.length > 0) {
      metadataReport.setUint8(offset, 1);
      offset++;

      for (; frameInfos.length > 0;) {
        var info = frameInfos.removeFirst();
        var serverDataKey = (info.timestamp / 1000).toInt();
        var firstFramePacketArrivalTimeMs =
            info.values["framesReceived"].toInt() + serverDataKey;
        var frameSubmittedTimeMs = firstFramePacketArrivalTimeMs;
        var frameDecodedTimeMs =
            info.values["framesDecoded"].toInt() + serverDataKey;
        var frameRenderedTimeMs = frameDecodedTimeMs;

        metadataReport.setUint32(offset, serverDataKey, Endian.little);
        metadataReport.setUint32(
            offset + 4, firstFramePacketArrivalTimeMs, Endian.little);
        metadataReport.setUint32(
            offset + 8, frameSubmittedTimeMs, Endian.little);
        metadataReport.setUint32(
            offset + 12, frameDecodedTimeMs, Endian.little);
        metadataReport.setUint32(
            offset + 16, frameRenderedTimeMs, Endian.little);
        metadataReport.setUint32(offset + 20, packetTimeNow, Endian.little);
        metadataReport.setUint32(
            offset + 24, DateTime.now().millisecondsSinceEpoch, Endian.little);
        offset += 28;
      }
    }

    if (inputStates.length > 0) {
      metadataReport.setUint8(offset, inputStates.length);
      offset++;

      for (; inputStates.length > 0;) {
        metadataReport.setUint8(offset, 0);
        offset++;

        var inputState = inputStates.removeFirst();
        var buttonMask = 0;
        if (inputState.nexus) {
          buttonMask |= 2;
        }
        if (inputState.menu) {
          buttonMask |= 4;
        }
        if (inputState.view) {
          buttonMask |= 8;
        }
        if (inputState.a) {
          buttonMask |= 16;
        }
        if (inputState.b) {
          buttonMask |= 32;
        }
        if (inputState.x) {
          buttonMask |= 64;
        }
        if (inputState.y) {
          buttonMask |= 128;
        }
        if (inputState.dPadUp) {
          buttonMask |= 256;
        }
        if (inputState.dPadDown) {
          buttonMask |= 512;
        }
        if (inputState.dPadLeft) {
          buttonMask |= 1024;
        }
        if (inputState.dPadRight) {
          buttonMask |= 2048;
        }
        if (inputState.leftShoulder) {
          buttonMask |= 4096;
        }
        if (inputState.rightShoulder) {
          buttonMask |= 8192;
        }
        if (inputState.leftThumb) {
          buttonMask |= 16384;
        }
        if (inputState.rightThumb) {
          buttonMask |= 32768;
        }

        metadataReport.setUint16(offset, buttonMask, Endian.little);
        metadataReport.setInt16(
            offset + 2, inputState.leftStickXAxis, Endian.little);
        metadataReport.setInt16(
            offset + 4, inputState.leftStickYAxis, Endian.little);
        metadataReport.setInt16(
            offset + 6, inputState.rightStickXAxis, Endian.little);
        metadataReport.setInt16(
            offset + 8, inputState.rightStickYAxis, Endian.little);
        metadataReport.setUint16(
            offset + 10, inputState.leftTrigger, Endian.little);
        metadataReport.setUint16(
            offset + 12, inputState.rightTrigger, Endian.little);
        metadataReport.setUint32(offset + 14, 0, Endian.little);
        metadataReport.setUint32(offset + 18, 0, Endian.little);

        offset += 22;
      }
    }

    return metadataReport.buffer.asUint8List();
  }

  @override
  void onMessage(RTCDataChannelMessage value) {
    if (value.type == MessageType.binary) {
      //debugPrint(
      //"${clientName} processor onMessage: ${json.encode(value.binary)}");
    } else {
      //debugPrint("${clientName} processor onMessage: ${value.text}");
    }
    //super.onMessage(value);
  }

  @override
  void onClose() {
    this.isRunning = false;
    super.onClose();
  }
}
