import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart' as mqtt;

void main() {
  runApp(BusApp());
}

class BusApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bus App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: BusStopsScreen(),
    );
  }
}

class BusStopsScreen extends StatefulWidget {
  @override
  _BusStopsScreenState createState() => _BusStopsScreenState();
}

class _BusStopsScreenState extends State<BusStopsScreen> {
  List<BusStop> busStops = [];
  mqtt.MqttClient? client;

  @override
  void initState() {
    super.initState();
    setupMqtt();
    loadBusStops();
  }

  Future<void> setupMqtt() async {
    final clientId = 'bus_app_${DateTime.now().millisecondsSinceEpoch}';
    client = mqtt.MqttClient('test.mosquitto.org', '1833');
    client!.port = 1883;
    client!.keepAlivePeriod = 30;
    client!.onDisconnected = handleDisconnected;
    client!.logging(on: true);

    final connMessage = mqtt.MqttConnectMessage()
        .authenticateAs('', '')
        .withClientIdentifier(clientId)
        .keepAliveFor(30)
        .withWillTopic('bsstatus')
        .withWillMessage('App disconnected')
        .startClean()
        .withWillQos(mqtt.MqttQos.atLeastOnce);

    try {
      await client!.connect(connMessage);
    } catch (e) {
      print('Exception: $e');
    }

    if (client!.connectionStatus!.state == mqtt.MqttConnectionState.connected) {
      print('MQTT client connected');
      client!.subscribe('/bsstatus/+', mqtt.MqttQos.atLeastOnce);
      client!.updates!.listen((List<mqtt.MqttReceivedMessage<mqtt.MqttMessage>> messages) {
        messages.forEach((message) {
          final topic = message.topic;
          final payload = mqtt.MqttPublishPayload.bytesToStringAsString(message.payload.message);
          handleMqttMessage(topic, payload);
        });
      });
    } else {
      print('MQTT client connection failed');
    }
  }

  void handleDisconnected() {
    print('MQTT client disconnected');
    // You can handle reconnection or other actions here
  }

  void handleMqttMessage(String topic, String payload) {
    final busStopNumber = topic.split('/').last;
    final data = jsonDecode(payload);
    final status = data['Status'] as String;

    setState(() {
      final busStop = busStops.firstWhere((bs) => bs.number == busStopNumber);
      busStop.status = (status.toLowerCase() == 'yes');
    });
  }

  Future<void> loadBusStops() async {
    String jsonString = '''
      {
        "busStops": [
          {
            "number": "001",
            "name": "KAP",
            "status": false
          },
          {
            "number": "002",
            "name": "Main Entrance",
            "status": false
          },
          {
            "number": "003",
            "name": "Blk 23",
            "status": false
          },
          {
            "number": "004",
            "name": "Sports Hall",
            "status": false
          },
          {
            "number": "005",
            "name": "SIT",
            "status": false
          },
          {
            "number": "006",
            "name": "Blk 44",
            "status": false
          },
          {
            "number": "007",
            "name": "Blk 37",
            "status": false
          },
          {
            "number": "008",
            "name": "Makan Place",
            "status": false
          },
          {
            "number": "009",
            "name": "Health Science",
            "status": false
          },
          {
            "number": "010",
            "name": "LSCT",
            "status": false
          },
          {
            "number": "011",
            "name": "Blk 72",
            "status": false
          }
        ]
      }
    ''';

    setState(() {
      busStops = (jsonDecode(jsonString)['busStops'] as List)
          .map((item) => BusStop.fromJson(item))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Bus Stops'),
      ),
      body: ListView.builder(
        itemCount: busStops.length,
        itemBuilder: (context, index) {
          final busStop = busStops[index];
          return ListTile(
            title: Text(busStop.name),
            trailing: busStop.status ? Icon(Icons.check_circle, color: Colors.green) : Icon(Icons.cancel, color: Colors.red),
          );
        },
      ),
    );
  }
}

class BusStop {
  final String number;
  final String name;
  bool status;

  BusStop({required this.number, required this.name, required this.status});

  factory BusStop.fromJson(Map<String, dynamic> json) {
    return BusStop(
      number: json['number'],
      name: json['name'],
      status: json['status'],
    );
  }
}
