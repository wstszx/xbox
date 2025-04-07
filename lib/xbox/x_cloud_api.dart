import "dart:convert";
import "package:flutter/foundation.dart";
import "package:http/http.dart" as http;

class XCloudApi {
  String token;
  String WlToken;
  late String sessionPath;

  XCloudApi(this.token, this.WlToken);

  static getUserToken(String gssvToken) async {
    var uri =
        Uri.parse("https://xhome.gssv-play-prod.xboxlive.com/v2/login/user");
    var data = {"token": gssvToken, "offeringId": "xhome"};

    var response = await http.post(uri,
        headers: {
          "Content-Type": "application/json",
          "x-gssv-client": "XboxComBrowser",
        },
        body: json.encode(data));

    if (response.statusCode == 200 || response.statusCode == 202) {
      return json.decode(response.body)["gsToken"];
    } else {
      return null;
    }
  }

  getDevices() async {
    var uri = Uri.parse(
        "https://uks.core.gssv-play-prodxhome.xboxlive.com/v6/servers/home");
    var response = await http.get(uri, headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer ${this.token}",
    });

    if (response.statusCode == 200) {
      debugPrint("XCloudApi getDevices() body: ${response.body}");
      return json.decode(response.body)["results"];
    }
    return null;
  }

  startSession(String serverId) async {
    var body = {
      "titleId": "",
      "systemUpdateGroup": "",
      "settings": {
        "nanoVersion": "V3;WebrtcTransport.dll",
        "enableTextToSpeech": false,
        "highContrast": 0,
        "locale": "en-US",
        "useIceConnection": false,
        "timezoneOffsetMinutes": 120,
        "sdkType": "web",
        "osName": "windows"
      },
      "serverId": serverId,
      "fallbackRegionNames": []
    };

    // var body = {
    //   "clientSessionId": '',
    //   "titleId": "",
    //   "systemUpdateGroup": "",
    //   "settings": {
    //     "nanoVersion": "V3;WebrtcTransport.dll",
    //     "enableTextToSpeech": false,
    //     "highContrast": 0,
    //     "locale": "en-US",
    //     "useIceConnection": false,
    //     "timezoneOffsetMinutes": 120,
    //     "sdkType": "web",
    //     "osName": "windows",
    //     // "magnifier": false,
    //   },
    //   "serverId": serverId,
    //   "fallbackRegionNames": []
    // };

    var deviceInfo = {
      "appInfo": {
        "env": {
          "clientAppId": "Microsoft.GamingApp",
          "clientAppType": "native",
          "clientAppVersion": "2203.1001.4.0",
          "clientSdkVersion": "5.3.0",
          // "clientSdkVersion": "8.5.2",
          "httpEnvironment": "prod",
          "sdkInstallId": ""
        }
      },
      "dev": {
        "hw": {
          "make": "Micro-Star International Co., Ltd.",
          "model": "GS66 Stealth 10SGS",
          "sdktype": "native"
        },
        "os": {
          "name": "Windows 10 Pro",
          "ver": "19041.1.amd64fre.vb_release.191206-1406"
        },
        "displayInfo": {
          "dimensions": {"widthInPixels": 1280, "heightInPixels": 720}, // Set initial request to 720p
          // "dimensions": {"widthInPixels": 800, "heightInPixels": 640},
          "pixelDensity": {"dpiX": 1, "dpiY": 1}
        }
      }
    };

    var response = await http.post(
        Uri.parse(
            "https://uks.core.gssv-play-prodxhome.xboxlive.com/v5/sessions/home/play"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer " + this.token,
          "X-MS-Device-Info": json.encode(deviceInfo),
        },
        body: json.encode(body));

    if (response.statusCode == 200 || response.statusCode == 202) {
      debugPrint('XCloudApi - startSession() response: 200');
      debugPrint("XCloudApi startSession() body: ${response.body}");
      var body = json.decode(response.body);
      var provisioningReady = await isProvisioningReady(body["sessionPath"]);
      if (provisioningReady != null) {
        this.sessionPath = body["sessionPath"];
        if (provisioningReady["state"] == "ReadyToConnect") {
          if (await xcloudAuth()) {
            return await isProvisioningReady(body["sessionPath"]);
          }
        } else {
          return provisioningReady;
        }
      }
    }
    return {"state": "request code is not 200 or 202!"};
  }

  Future isProvisioningReady(String url, {int retries = 0}) async {
    var response = await http.get(
        Uri.parse("https://uks.core.gssv-play-prodxhome.xboxlive.com/${url}/state"),
        // Uri.parse(
        //     "https://uks.core.gssv-play-prodxhome.xboxlive.com/v4/sessions/home/${url}/state"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer " + this.token,
        });

    if (response.statusCode == 200) {
      //debugPrint("XCloudApi isProvisioningReady() body: ${response.body}");
      var body = json.decode(response.body);
      //debugPrint("XCloudApi isProvisioningReady() state: ${body["state"]}");
      if (body["state"] == "Provisioned" || body["state"] == "ReadyToConnect") {
        return body;
      } else if (body["state"] == "Failed") {
        //debugPrint("XCloudApi isProvisioningReady() state: Failed");
        return body;
      } else {
        if (retries > 30) {
          //debugPrint("XCloudApi isProvisioningReady() timeout");
          return {"state": "timeout"};
        }
        //debugPrint("XCloudApi isProvisioningReady() waiting...");
        await Future.delayed(Duration(milliseconds: 1000));
        return await isProvisioningReady(url, retries: ++retries);
      }
    } else {
      if (retries > 30) {
        //debugPrint("XCloudApi isProvisioningReady() timeout");
        return {"state": "timeout"};
      }
      //debugPrint("XCloudApi isProvisioningReady() waiting...");
      await Future.delayed(Duration(milliseconds: 1000));
      return await isProvisioningReady(url, retries: ++retries);
    }
  }

  isExchangeReady(String url, {int retries = 0}) async {
    var response = await http.get(
        Uri.parse(
            "https://uks.core.gssv-play-prodxhome.xboxlive.com/${this.sessionPath}/${url}"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer " + this.token,
        });

    if (response.statusCode == 200) {
      //debugPrint("XCloudApi isExchangeReady() body: ${response.body}");
      var body = response.body
          .replaceAll("\\\"", "\"")
          .replaceAll("\"[", "[")
          .replaceAll("\"{", "{")
          .replaceAll("}\"", "}")
          .replaceAll("\"[", "[")
          .replaceAll("]\"", "]")
          .replaceAll("\\\\\"", "\"")
          .replaceAll("\\\\\\", "\\")
          .replaceAll("\\\\r", "\\r")
          .replaceAll("\\\\n", "\\n");
      return json.decode(body);
    } else {
      if (retries > 30) {
        //debugPrint("XCloudApi isExchangeReady() timeout");
        return null;
      }
      //debugPrint("XCloudApi isExchangeReady() waiting...");
      await Future.delayed(Duration(milliseconds: 1000));
      return await isExchangeReady(url, retries: ++retries);
    }
  }

  sendSdp(String sdp) async {
    var body = {
      "messageType": "offer",
      "sdp": sdp,
      "configuration": {
        "chatConfiguration": {
          "bytesPerSample": 2,
          "expectedClipDurationMs": 20,
          "format": {"codec": "opus", "container": "webm"},
          "numChannels": 1,
          "sampleFrequencyHz": 24000
        },
        "chat": {"minVersion": 1, "maxVersion": 1},
        "control": {"minVersion": 1, "maxVersion": 3},
        "input": {"minVersion": 1, "maxVersion": 7},
        "message": {"minVersion": 1, "maxVersion": 1},
      }
    };

    var response = await http.post(
        Uri.parse(
            "https://uks.core.gssv-play-prodxhome.xboxlive.com/${this.sessionPath}/sdp"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer " + this.token,
        },
        body: json.encode(body));

    debugPrint("XCloudApi sendSdp() Status: ${response.statusCode}");
    debugPrint("XCloudApi sendSdp() body: ${response.body}");
    if (response.statusCode == 202) {
      //debugPrint("XCloudApi sendSdp() body: ${response.body}");
      var exchangeReady = await this.isExchangeReady("sdp");
      if (exchangeReady != null) {
        //debugPrint("Loop done? resolve now...");
        return exchangeReady["exchangeResponse"];
      }
    }
    return null;
  }

  sendChatSdp(String sdp) async {
    var body = {
      "messageType": "offer",
      "sdp": sdp,
      "configuration": {
        'isMediaStreamsChatRenegotiation': true,
      }
    };

    var response = await http.post(
        Uri.parse(
            "https://uks.core.gssv-play-prodxhome.xboxlive.com/${this.sessionPath}/sdp"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer " + this.token,
        },
        body: json.encode(body));

    //debugPrint("XCloudApi sendSdp() Status: ${response.statusCode}");
    if (response.statusCode == 202) {
      //debugPrint("XCloudApi sendSdp() body: ${response.body}");
      var exchangeReady = await this.isExchangeReady("sdp");
      if (exchangeReady != null) {
        //debugPrint("Loop done? resolve now...");
        return exchangeReady["exchangeResponse"];
      }
    }
    return null;
  }

  sendIce(String ice) async {
    var body = {"messageType": "iceCandidate", "candidate": ice};

    var response = await http.post(
        Uri.parse(
            "https://uks.core.gssv-play-prodxhome.xboxlive.com/${this.sessionPath}/ice"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer " + this.token,
        },
        body: json.encode(body));

    debugPrint("XCloudApi sendIce() Status: ${response.statusCode}");
    debugPrint("XCloudApi sendIce() body: ${response.body}");
    if (response.statusCode == 202) {
      //debugPrint("XCloudApi sendIce() body: ${response.body}");
      var exchangeReady = await this.isExchangeReady("ice");
      if (exchangeReady != null) {
        //debugPrint("Loop done? resolve now...");
        return exchangeReady["exchangeResponse"];
      }
    }
    return null;
  }

  // sendIce(String ice) async {
  //   if (this.sessionPath == null || this.sessionPath.isEmpty) {
  //     debugPrint("Session is not ready for ICE exchange.");
  //     return null;
  //   }
  //
  //   if (this.token == null || this.token.isEmpty) {
  //     debugPrint("Authorization token is missing or invalid.");
  //     return null;
  //   }
  //
  //   var body = {"messageType": "iceCandidate", "candidate": ice};
  //
  //   var exchangeReady = await this.isExchangeReady("ice");
  //   if (exchangeReady == null) {
  //     debugPrint("ICE exchange is not ready yet. Retrying...");
  //     await Future.delayed(Duration(seconds: 2));
  //     exchangeReady = await this.isExchangeReady("ice");
  //     if (exchangeReady == null) {
  //       debugPrint("ICE exchange is still not ready. Aborting.");
  //       return null;
  //     }
  //   }
  //
  //   var response = await http.post(
  //     Uri.parse(
  //         "https://uks.core.gssv-play-prodxhome.xboxlive.com/${this.sessionPath}/ice"),
  //     headers: {
  //       "Content-Type": "application/json",
  //       "Authorization": "Bearer " + this.token,
  //     },
  //     body: json.encode(body),
  //   );
  //
  //   if (response.statusCode == 202) {
  //     debugPrint("ICE exchange request accepted.");
  //     return exchangeReady["exchangeResponse"];
  //   } else {
  //     debugPrint("Failed to send ICE candidate. Status: ${response.statusCode}");
  //   }
  //
  //   return null;
  // }


  xcloudAuth() async {
    var body = {"userToken": this.WlToken};

    var response = await http.post(
        Uri.parse(
            "https://uks.core.gssv-play-prodxhome.xboxlive.com/${this.sessionPath}/connect"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer " + this.token,
        },
        body: json.encode(body));

    //debugPrint("XCloudApi xcloudAuth() Status: ${response.statusCode}");
    if (response.statusCode == 200 || response.statusCode == 202) {
      //debugPrint("XCloudApi sendIce() body: ${response.body}");
      return true;
    }
    return false;
  }

  KeepAlive() async {
    try {
      var response = await http.post(
          Uri.parse(
              "https://uks.gssv-play-prodxhome.xboxlive.com/${this.sessionPath}/keepalive"),
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer " + this.token,
          },
          body: json.encode(""));

      //debugPrint("XCloudApi KeepAlive() Status: ${response.statusCode}");
      if (response.statusCode == 200) {
        debugPrint("XCloudApi KeepAlive() body: ${response.body}");
        return true;
      }
      return false;
    } catch (err) {
      return false;
    }
  }
}
