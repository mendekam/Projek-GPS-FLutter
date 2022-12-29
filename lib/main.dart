import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'dart:async';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:gpsprojek/location_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Maps Gemblong',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: const OrderTrackingPage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
        appBar: AppBar(
          // Here we take the value from the MyHomePage object that was created by
          // the App.build method, and use it to set our appbar title.
          title: Text(widget.title),
        ),
        body: Center());
  }
}

class OrderTrackingPage extends StatefulWidget {
  const OrderTrackingPage({Key? key}) : super(key: key);
  @override
  State<OrderTrackingPage> createState() => OrderTrackingPageState();
}

class OrderTrackingPageState extends State<OrderTrackingPage> {
  final Completer<GoogleMapController> _controller = Completer();
  TextEditingController _sourceController = TextEditingController();
  TextEditingController _destinationController = TextEditingController();
  static const LatLng initLocation = LatLng(37.33500926, -122.03272188);

  Set<Marker> _markers = Set<Marker>();
  Set<Polyline> _polylines = Set<Polyline>();
  List<LatLng> polylineCoordinates = <LatLng>[];

  int _polylineCounter = 1;
  double distance = 0.0;

  @override
  void initState() {
    super.initState();
    _setMarker(LatLng(37.33500926, -122.03272188));
  }

  void _setPolyline(List<PointLatLng> points) {
    final String polylineIdValue = 'polyline_$_polylineCounter';

    _polylines.add(
      Polyline(
        polylineId: PolylineId(polylineIdValue),
        width: 3,
        color: Color.fromARGB(255, 247, 17, 147),
        points: points
            .map(
              (point) => LatLng(point.latitude, point.longitude),
            )
            .toList(),
      ),
    );

    double totalDistance = 0;
    for (var i = 0; i < points.length - 1; i++) {
      totalDistance += calculateDistance(
          points[i].latitude,
          points[i].longitude,
          points[i + 1].latitude,
          points[i + 1].longitude);
    }

    print(totalDistance);

    setState(() {
      distance = totalDistance;
    });
  }

  void _setMarker(LatLng point) {
    setState(() {
      _markers.add(
        Marker(
          markerId: MarkerId('marker'),
          draggable: true,
          position: point,
        ),
      );
    });
  }

  double calculateDistance(lat1, lon1, lat2, lon2) {
    var p = 0.017453292519943295;
    var a = 0.5 -
        cos((lat2 - lat1) * p) / 2 +
        cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Directioff'),
          backgroundColor: Color.fromARGB(255, 247, 17, 147),
        ),
        body: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                    child: TextFormField(
                      controller: _sourceController,
                      decoration: InputDecoration(
                        hintText: 'Search Source...',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        print(value);
                      },
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                    child: TextFormField(
                      controller: _destinationController,
                      decoration: InputDecoration(
                        hintText: 'Search Destination...',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        print(value);
                      },
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () async {
                    var directions = await LocationService().getDirections(
                      _sourceController.text,
                      _destinationController.text,
                    );
                    _goToPlace(
                      directions['end_location']['lat'],
                      directions['end_location']['lng'],
                      directions['bounds_ne'],
                      directions['bounds_sw'],
                    );
                    _setPolyline(directions['polyline_decoded']);
                  },
                  icon: Icon(Icons.search),
                ),
              ],
            ),
            Expanded(
              child: GoogleMap(
                mapType: MapType.normal,
                initialCameraPosition: const CameraPosition(
                  target: initLocation,
                  zoom: 12,
                ),
                markers: _markers,
                polylines: _polylines,
                onMapCreated: (mapController) {
                  _controller.complete(mapController);
                },
              ),
            ),
            Positioned(
              bottom: 200,
              left: 50,
              child: Container(
                child: Card(
                  child: Container(
                    padding: EdgeInsets.all(20),
                    child: Text(
                        "Total Distance: " +
                            distance.toStringAsFixed(2) +
                            " KM",
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
            ),
          ],
        ));
  }

  Future<void> _goToPlace(
    //Map<String, dynamic> place
    double lat,
    double lng,
    Map<String, dynamic> boundsNe,
    Map<String, dynamic> boundsSw,
  ) async {
    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(CameraUpdate.newCameraPosition(
      CameraPosition(
        target: LatLng(lat, lng),
        zoom: 13,
      ),
    ));
    controller.animateCamera(
      CameraUpdate.newLatLngBounds(
          LatLngBounds(
            southwest: LatLng(boundsSw['lat'], boundsSw['lng']),
            northeast: LatLng(boundsNe['lat'], boundsNe['lng']),
          ),
          25),
    );
    _setMarker(
      LatLng(lat, lng),
    );
  }
}
