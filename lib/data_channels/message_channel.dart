import "dart:convert";
import "dart:io";
import "package:flutter_webrtc/flutter_webrtc.dart";
import "package:xbox_remote_play/Config.dart";
import "package:xbox_remote_play/data_channels/control_channel.dart";
import "channel_base.dart";
import "../xbox/x_cloud_client.dart";
import "input_channel.dart";

class MessageChannel extends ChannelBase {

  MessageChannel(XCloudClient client, String clientName)
      : super(client, clientName);

  @override
  void onOpen() {
    super.onOpen();

    var handshake = {
      "type": "Handshake",
      "version": "messageV1",
      "id": "f9c5f412-0e69-4ede-8e62-92c7f5358c56",
      "cv": "",
    };
    this.sendMessage(json.encode(handshake));
  }

  @override
  void onMessage(RTCDataChannelMessage value) async{
    super.onMessage(value);
    Map<String, dynamic> message = json.decode(value.text);
    if (message["type"] == "HandshakeAck") {

      (this.client.getLocalChannel("control") as ControlChannel).start();
      (this.client.getLocalChannel("input") as InputChannel).start();

      var uiConfig = {
        "type": "Message",
        "content": json.encode({
          "version": [0, 1, 0],
          "systemUis": [33],
        }),
        "id": "41f93d5a-900f-4d33-b7a1-2d4ca6747072",
        "target": "/streaming/systemUi/configuration",
        "cv": ""
      };
      this.sendMessage(json.encode(uiConfig));

      var clientConfig = {
        "type": "Message",
        "content": json.encode({
          "clientAppInstallId": "c11ddb2e-c7e3-4f02-a62b-fd5448e0b851",
        }),
        "id": "41f93d5a-900f-4d33-b7a1-2d4ca6747072",
        "target": "/streaming/properties/clientappinstallidchanged",
        "cv": ""
      };
      this.sendMessage(json.encode(clientConfig));

      var orientationConfig = {
        "type": "Message",
        "content": json.encode({
          "orientation": 0,
        }),
        "id": "41f93d5a-900f-4d33-b7a1-2d4ca6747072",
        "target": "/streaming/characteristics/orientationchanged",
        "cv": ""
      };
      this.sendMessage(json.encode(orientationConfig));

      var touchConfig = {
        "type": "Message",
        "content": json.encode({
          "touchInputEnabled": false,
        }),
        "id": "41f93d5a-900f-4d33-b7a1-2d4ca6747072",
        "target": "/streaming/characteristics/touchinputenabledchanged",
        "cv": ""
      };
      this.sendMessage(json.encode(touchConfig));

      var deviceConfig = {
        "type": "Message",
        "content": json.encode({}),
        "id": "41f93d5a-900f-4d33-b7a1-2d4ca6747072",
        "target": "/streaming/characteristics/clientdevicecapabilities",
        "cv": ""
      };
      this.sendMessage(json.encode(deviceConfig));

      var dimensionsConfig = {
        "type": "Message",
        "content": json.encode({
          "horizontal": Config.Width,
          "vertical":  Config.Height,
          "preferredWidth":  Config.Width,
          "preferredHeight": Config.Height,
          "safeAreaLeft": 0,
          "safeAreaTop": 0,
          "safeAreaRight":  Config.Width,
          "safeAreaBottom": Config.Height,
          "supportsCustomResolution": true,
        }),
        "id": "41f93d5a-900f-4d33-b7a1-2d4ca6747072",
        "target": "/streaming/characteristics/dimensionschanged",
        "cv": ""
      };
      this.sendMessage(json.encode(dimensionsConfig));
    }
  }

  @override void onClose() {
    // TODO: implement onClose
    super.onClose();
  }
}


