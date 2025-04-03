import 'channel_base.dart';

import '../xbox/x_cloud_client.dart';

class ChatChannel extends ChannelBase {
  ChatChannel(XCloudClient client, String clientName)
      : super(client, clientName);
}
