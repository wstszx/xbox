import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../xbox/x_cloud_client.dart';

class ChannelBase {
  XCloudClient client;
  String clientName;

  ChannelBase(
    this.client,
    this.clientName,
  );

  void onOpen(){
      //debugPrint("${clientName} processor onOpen");
  }

  void onMessage(RTCDataChannelMessage value){
    if(value.type == MessageType.binary){
      //debugPrint("${clientName} processor onMessage: ${json.encode(value.binary)}");
    }
    else{
      //debugPrint("${clientName} processor onMessage: ${value.text}");
    }
  }

  void onClose(){
    //debugPrint("${clientName} processor onClose");
  }

  Future<void> sendMessage(String message) async{
    var dc = this.client.getRemoteChannel(this.clientName);
    await dc?.send(RTCDataChannelMessage(message));
  }

  Future<void> sendData(Uint8List data) async{
    var dc = this.client.getRemoteChannel(this.clientName);
    await dc?.send(RTCDataChannelMessage.fromBinary(data));
  }
}
