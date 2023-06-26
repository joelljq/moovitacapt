import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart' as mqtt;
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

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
  final MqttServerClient client = MqttServerClient('test.mosquitto.org', '1833');
  String status = "Disconnected";
  Color statuscolor = Colors.red;

  @override
  void initState() {
    super.initState();
    setupMqtt();
    loadBusStops();
  }

  Future<void> setupMqtt() async {
    try {
      await client!.connect();
    } catch (e) {
      print('Exception: $e');
    }

    if (client!.connectionStatus!.state == mqtt.MqttConnectionState.connected) {
      setState(() {
        status = "Connected";
        print(status.toString());
        statuscolor = Colors.green;
        print('MQTT client connected');
        client!.subscribe('/bsstatus/+', mqtt.MqttQos.atLeastOnce);
        client!.updates!.listen((List<mqtt.MqttReceivedMessage<mqtt.MqttMessage>> messages) {
          messages.forEach((message) {
            final topic = message.topic;
            final recMess = messages![0].payload as MqttPublishMessage;
            final String payload = utf8.decode(recMess.payload.message);
            handleMqttMessage(topic, payload);
          });
        });
      });
    } else {
      setState(() {
        print('MQTT client connection failed');
        status = "Disconnected";
        statuscolor = Colors.red;
      });
    }
  }


  void handleDisconnected() {
    setState(() {
      print('MQTT client disconnected');
      status = "Disconnected";
      statuscolor = Colors.red;
    });
    // You can handle reconnection or other actions here
  }

  void handleMqttMessage(String topic, String payload) {
    final int busStopNumber = int.parse(topic.split('/').last);
    final data = jsonDecode(payload);
    final status = data['Status'] as String;
    print(busStopNumber.toString());
    setState(() {
      final busStop = busStops[busStopNumber - 1];
      busStop.status = status == "Yes"? true : false;
    });
  }


  Future<void> loadBusStops() async {
    String jsonString = '''
      {
        "busStops": [
          {
            "name": "KAP",
            "status": false
          },
          {
            "name": "Main Entrance",
            "status": false
          },
          {
            "name": "Blk 23",
            "status": false
          },
          {
            "name": "Sports Hall",
            "status": false
          },
          {
            "name": "SIT",
            "status": false
          },
          {
            "name": "Blk 44",
            "status": false
          },
          {
            "name": "Blk 37",
            "status": false
          },
          {
            "name": "Makan Place",
            "status": false
          },
          {
            "name": "Health Science",
            "status": false
          },
          {
            "name": "LSCT",
            "status": false
          },
          {
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
        title: Text('Moovita Bus Stops Statuses', style: TextStyle(fontWeight: FontWeight.bold),),
        backgroundColor: Color(0xFF671919),
      ),
      body: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.grey,
              borderRadius: BorderRadius.circular(20.0),
            ),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                status,
                style: TextStyle(
                  color: statuscolor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: setupMqtt,
              child: ListView.builder(
                itemCount: busStops.length,
                itemBuilder: (context, index) {
                  final busStop = busStops[index];
                  return ListTile(
                    title: Text(busStop.name, style: TextStyle(fontWeight: FontWeight.bold),),
                    trailing: busStop.status ? Icon(Icons.check_circle, color: Colors.green) : Icon(Icons.cancel, color: Colors.red),
                  );
                },
              ),
            ),
          ),
        ],
      )
    );
  }
}

class BusStop {
  final String name;
  bool status;

  BusStop({required this.name, required this.status});

  factory BusStop.fromJson(Map<String, dynamic> json) {
    return BusStop(
      name: json['name'],
      status: json['status'],
    );
  }
}
