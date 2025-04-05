import 'package:flutter/widgets.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../data_channels/channel_base.dart';
import '../data_channels/chat_channel.dart';
import '../data_channels/control_channel.dart';
import '../data_channels/input_channel.dart';
import '../data_channels/message_channel.dart';

class XCloudClient {
  late RTCPeerConnection pc;
  late RTCRtpTransceiver transceiver;

  Map<String, RTCDataChannelInit> channelInits = {
    "chat": RTCDataChannelInit()
      ..protocol = "chatV1"
      ..ordered = false,
    "control": RTCDataChannelInit()
      ..protocol = "controlV1"
      ..ordered = false,
    "input": RTCDataChannelInit()
      ..protocol = "1.0"
      ..ordered = true,
    "message": RTCDataChannelInit()
      ..protocol = "messageV1"
      ..ordered = false,
  };

  List<RTCIceCandidate> iceCandidates = [];

  Map<String, RTCDataChannel> remoteChannels = {};
  Map<String, ChannelBase> localChannels = {};

  Function(MediaStream stream)? onAddStream;
  Function(RTCIceConnectionState state)? onConnectionState;

  Future initialize() async {
    try {
      await WebRTC.initialize(options: {"logLevel": "info"});

      this.pc = await createPeerConnection({
        "iceServers": [
          {"url": "stun:stun.l.google.com:19302"},
          {"url": "stun:stun1.l.google.com:19302"},
        ]
      });

      this.pc.onIceConnectionState = (state) {
        if (state == RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
          debugPrint("XCloudClient peerConnection state: connected");
          onConnectionState?.call(state);
        } else if (state ==
            RTCPeerConnectionState.RTCPeerConnectionStateDisconnected) {
          debugPrint("XCloudClient peerConnection state: disconnected");
          onConnectionState?.call(state);
        } else if (state ==
            RTCPeerConnectionState.RTCPeerConnectionStateClosed) {
          debugPrint("XCloudClient peerConnection state: closed");
          onConnectionState?.call(state);
        } else if (state ==
            RTCPeerConnectionState.RTCPeerConnectionStateFailed) {
          debugPrint("XCloudClient peerConnection state: failed");
          onConnectionState?.call(state);
        }
      };

      await createChannels();
      gatherIce();

      this.transceiver = await this.pc.addTransceiver(
          kind: RTCRtpMediaType.RTCRtpMediaTypeVideo,
          init:
              RTCRtpTransceiverInit(direction: TransceiverDirection.RecvOnly));

        // await this.pc.addTransceiver(  // 注释掉音频 transceiver
        //   kind: RTCRtpMediaType.RTCRtpMediaTypeAudio,
        //   init:
        //   RTCRtpTransceiverInit(direction: TransceiverDirection.SendRecv));
      //StatsReport
      this.pc.onAddStream = (stream) async {
        var stats = await transceiver.receiver.getStats();
        // if (stats[0].timestamp / 1000 <
        //     DateTime(2023, 9, 11).millisecondsSinceEpoch) {
        //   onAddStream?.call(stream);
        // }

        onAddStream?.call(stream);
      };
    } catch (e) {
      debugPrint("XCloudClient initialize() throw: ${e.toString()}");
    }
  }

  Future<RTCSessionDescription> createOffer() async {
    final Map<String, dynamic> constraints = {
      'mandatory': {
        'OfferToReceiveAudio': false,
        'OfferToReceiveVideo': true,
      }
    };
    var offer = await this.pc.createOffer(constraints);
    await this.pc.setLocalDescription(offer);
    return offer;
  }

  Future setRemoteOffer(String sdp) async {
   await  this.pc.setRemoteDescription(RTCSessionDescription(sdp, "answer"));
  }

  Future createChannels() async {
    try {
      for (var init in channelInits.entries) {
        var key = init.key;
        var value = init.value;
        var channel = await pc.createDataChannel(key, value);

        switch (key) {
          case "message":
            localChannels[key] = MessageChannel(this, key);
            break;
          case "chat":
            localChannels[key] = ChatChannel(this, key);
            break;
          case "control":
            localChannels[key] = ControlChannel(this, key);
            break;
          case "input":
            localChannels[key] = InputChannel(this, key);
            break;
        }

        channel.onDataChannelState = (state) {
          if (state == RTCDataChannelState.RTCDataChannelOpen) {
            localChannels[key]?.onOpen();
          } else if (state == RTCDataChannelState.RTCDataChannelClosed) {
            localChannels[key]?.onClose();
          }
        };
        channel.onMessage = localChannels[key]?.onMessage;
        remoteChannels[key] = channel;
      }
    } catch (e) {
       debugPrint("XCloudClient createChannels() throw: ${e.toString()}");
    }
  }

  void gatherIce() {
    this.pc.onIceCandidate = (candidate) {
      if (candidate.candidate != null && candidate.candidate!.isNotEmpty) {
        this.iceCandidates.add(candidate);
        debugPrint("XCloudClient add ice");
      }
    };
  }

  RTCDataChannel? getRemoteChannel(String name) {
    if (remoteChannels.containsKey(name)) {
      return remoteChannels[name];
    }
    return null;
  }

  ChannelBase? getLocalChannel(String name) {
    if (localChannels.containsKey(name)) {
      return localChannels[name];
    }
    return null;
  }

  close() {
    for (var channel in remoteChannels.values) {
      channel.close();
    }

    for (var channel in localChannels.values) {
      channel.onClose();
    }

    this.pc.close();
  }
}
