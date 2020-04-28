import 'dart:async';
import 'dart:typed_data';

import 'package:ecobici/helpers/json_reader_helper.dart';
import 'package:ecobici/models/station.dart';
import 'package:ecobici/styles/map_styles.dart';
import 'package:ecobici/styles/my_colors.dart';
import 'package:ecobici/widgets/station_list_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:location/location.dart' as myLocation;
import 'dart:ui' as ui;

enum OrderBy {id, bikes, slots, distance}
class MapView extends StatefulWidget {
  @override
  _MapViewState createState() => _MapViewState();
}

class _MapViewState extends State<MapView> {
  final mainScaffoldKey = GlobalKey<ScaffoldState>();
  Completer<GoogleMapController> _controller = Completer();
  GoogleMapController mapController;
  Map<MarkerId, Marker> markers = {};
  Map currentLocation = {};
  double nearbyRadius = 1000.0;
  LatLng mockLocation = LatLng(19.431906, -99.133136);
  List<Station> nearbyStationList = List();
  List<Station> completeStationList = List();
  OrderBy _orderBy = OrderBy.id;
  bool _isBusy = false;

  static final CameraPosition _initialPosition = CameraPosition(
    target: LatLng(19.431906, -99.133136),
    zoom: 14.4746,
  );

  @override
  initState() {
    super.initState();
    checkLocationPermission().then((hasPermission) {
      initLocationTracking();
    });
    WidgetsBinding.instance.addPostFrameCallback(onViewCreated);
  }

  void onMapCreated(GoogleMapController controller) {
    mapController = controller;
    mapController.setMapStyle(MapStyles.Silver);
    _controller.complete(mapController);
  }

  onViewCreated(_) async {
    await getInfoBikes();
  }

  getInfoBikes() async {

    setState(() {
      _isBusy = true;
    });

    await jsonReader.getInfoBikes(context).then((stationList) {
      stationList.forEach((station) async {
        Station _station = Station.fromMap(station);
        setState(() {
          completeStationList.add(_station);
        });
      });

      getNearbyStationsList();
    });

    setState(() {
      _isBusy = false;
    });
  }

  getNearbyStationsList() {
    setState(() {
      nearbyStationList.clear();
      markers.clear();
      _isBusy = true;
    });

    completeStationList.forEach((station) async {
      double distanceInMeters = await Geolocator().distanceBetween(
          currentLocation['lat'] ?? mockLocation.latitude,
          currentLocation['lng'] ?? mockLocation.longitude,
          double.parse(station.lat),
          double.parse(station.lon));

      station.distance = distanceInMeters;

      if (distanceInMeters <= nearbyRadius) {
        setState(() {
          nearbyStationList.add(station);
        });
      }

      await setMarkersOnMap();
    });

    setState(() {
      _isBusy = false;
    });
  }

  Future<bool> checkLocationPermission() async {
    ///check status of location Permission
    PermissionStatus permission = await Permission.location.status;

    if (permission != PermissionStatus.granted) {
      ///request location Permission
      Map<Permission, PermissionStatus> permissions = await [Permission.location].request();

      if (permissions.containsKey(Permission.location)) {
        if (permissions.containsValue(PermissionStatus.granted)) {
          return true;
        } else {
          return false;
        }
      }
    } else {
      return true;
    }
    return false;
  }

  initLocationTracking() async {
    var location = new myLocation.Location();
    await location.getLocation();

    location.onLocationChanged.listen((myLocation.LocationData _currentLocation) {
      setState(() {
        currentLocation = {
          'lat': _currentLocation.latitude,
          'lng': _currentLocation.longitude,
          'alt': _currentLocation.altitude,
          'acc': _currentLocation.accuracy,
          'spd': _currentLocation.speed,
          'spdAcc': _currentLocation.speedAccuracy,
          'hdn': _currentLocation.heading,
          'tms': _currentLocation.time
        };
      });
    });

    return currentLocation;
  }

  setMarkersOnMap() async {

    setState(() {
      _isBusy = true;
    });

    nearbyStationList.forEach((station) async {
      //Uint8List markerIcon = await getBytesFromAsset("assets/icons/bike.png", 80);
      double _latitude = double.parse(station.lat);
      double _longitude = double.parse(station.lon);

      LatLng latLngMarker = LatLng(_latitude, _longitude);

      final MarkerId markerId = MarkerId("marker_${station.id}");

      final Marker marker = Marker(
        markerId: markerId,
        position: latLngMarker,
        //icon: BitmapDescriptor.fromBytes(markerIcon),
        icon: BitmapDescriptor.defaultMarkerWithHue(270.0),
        infoWindow: InfoWindow(title: station.name, snippet: 'Distancia: ${(station.distance / 1000).toStringAsFixed(2)} km'),
      );

      setState(() {
        markers[markerId] = marker;
      });
    });

    setState(() {
      _isBusy = false;
    });
  }

  Future<Uint8List> getBytesFromAsset(String path, double height) async {
    ByteData data = await rootBundle.load(path);
    ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List(), targetHeight: height.round());
    ui.FrameInfo fi = await codec.getNextFrame();
    return (await fi.image.toByteData(format: ui.ImageByteFormat.png)).buffer.asUint8List();
  }

  showLocationOnMap(double lat, double lng, {double zoom}) async {
    mapController.animateCamera(
        CameraUpdate.newLatLngZoom(LatLng(lat, lng), zoom ?? 15));
  }

  orderNearbyStationList(){
    switch (_orderBy){
      case OrderBy.id:
        setState(() {
          nearbyStationList.sort((a, b) => a.id.compareTo(b.id));
        });
        break;
      case OrderBy.bikes:
        setState(() {
          nearbyStationList.sort((a, b) => b.bikes.compareTo(a.bikes));
        });
        break;
      case OrderBy.slots:
        setState(() {
          nearbyStationList.sort((a, b) => a.slots.compareTo(b.slots));
        });
        break;
      case OrderBy.distance:
        setState(() {
          nearbyStationList.sort((a, b) => a.distance.compareTo(b.distance));
        });
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: mainScaffoldKey,
      endDrawer: filterDrawer(),
      body: SafeArea(
        top: false,
        bottom: false,
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: <Widget>[
            GoogleMap(
              padding: EdgeInsets.only(bottom: (MediaQuery.of(context).size.height / 2) - 60),
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              onMapCreated: onMapCreated,
              initialCameraPosition: _initialPosition,
              mapToolbarEnabled: false,
              markers: Set<Marker>.of(markers.values),
            ),
            floatingButtonsLayer(),
            listContainer(),
            Visibility(
              visible: _isBusy,
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(
                  sigmaX: 5,
                  sigmaY: 5,
                ),
                child: Center(child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                    SizedBox(height: 10,),
                    Text("Cargando estaciones...", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.white),),
                  ],
                ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget floatingButtonsLayer() {
    return Positioned(
      top: 8,
      right: 8,
      child: SafeArea(child: Column(
        children: <Widget>[
          FloatingActionButton(
            heroTag: 'filter',
            onPressed: () {
              mainScaffoldKey.currentState.openEndDrawer();
            },
            elevation: 6,
            child: Icon(Icons.filter_list),
            backgroundColor: MyColors.primaryColor,
          ),
          SizedBox(
            height: 8,
          ),
          FloatingActionButton(
            heroTag: 'myLocation',
            onPressed: () {
              showLocationOnMap(currentLocation["lat"] ?? mockLocation.latitude, currentLocation["lng"] ?? mockLocation.longitude);
            },
            elevation: 6,
            child: Icon(Icons.my_location),
            backgroundColor: MyColors.primaryColor,
          ),
        ],
      )),
    );
  }

  Widget listContainer() {
    return GestureDetector(
      child: AnimatedContainer(
        duration: Duration(milliseconds: 750),
        padding: EdgeInsets.only(top: 10),
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height / 2,
        decoration: BoxDecoration(
          color: MyColors.primaryColor,
          border: Border.all(width: 1, color: Colors.grey.withOpacity(0.5)),
          borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
        ),
        child: Column(
          children: <Widget>[
            Container(
              padding: EdgeInsets.all(10),
              child: Text(
                "Estaciones cercanas (${(nearbyRadius.round() / 1000).toStringAsFixed(1)} km): ${nearbyStationList.length}",
                style: TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.w500),
              ),
            ),
            Expanded(
              child: ListView.separated(
                itemCount: nearbyStationList.length,
                separatorBuilder: (context, index) => SizedBox(
                  height: 3,
                ),
                itemBuilder: (context, index) {
                  return Container(
                    padding: EdgeInsets.all(5),
                    color: MyColors.primaryColor,
                    child: InkWell(
                        onTap: () {
                          showLocationOnMap(
                              double.parse(nearbyStationList[index].lat),
                              double.parse(nearbyStationList[index].lon),
                              zoom: 17.0);
                        },
                        child: StationListTile(
                            id: nearbyStationList[index].id.toString(),
                            name: nearbyStationList[index].name,
                            address: nearbyStationList[index].address,
                            distance: nearbyStationList[index].distance.toString(),
                            bikes: nearbyStationList[index].bikes.toString(),
                            slots: nearbyStationList[index].slots.toString())),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget filterDrawer() {
    return Drawer(
      elevation: 12,
      child: SafeArea(
        child: Column(
          children: <Widget>[
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                  margin: EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                  child: Text(
                    "Filtros:",
                    style: TextStyle(fontSize: 16),
                  )),
            ),
            Text(
                "Rango de Distancia (${(nearbyRadius.round() / 1000).toStringAsFixed(1)} km)"),
            Slider(
              min: 1,
              max: 10,
              value: nearbyRadius / 1000,
              divisions: 10,
              onChanged: (value) {
                setState(() {
                  nearbyRadius = value * 1000;
                });
              },
              onChangeEnd: (value) async {
                await getNearbyStationsList();
                orderNearbyStationList();
              },
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                  margin: EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                  child: Text(
                    "Ordenar por:",
                    style: TextStyle(fontSize: 16),
                  )),
            ),
        Column(
          children: <Widget>[
            ListTile(
              title: Text('Numero de estacion'),
              leading: Radio(
                value: OrderBy.id,
                groupValue: _orderBy,
                onChanged: (OrderBy value) {
                  setState(() { _orderBy = value;  });
                  orderNearbyStationList();
                  Navigator.of(context).pop();
                },
              ),
            ),
            ListTile(
              title: Text('Menor distancia'),
              leading: Radio(
                value: OrderBy.distance,
                groupValue: _orderBy,
                onChanged: (OrderBy value) {
                  setState(() { _orderBy = value;  });
                  orderNearbyStationList();
                  Navigator.of(context).pop();
                },
              ),
            ),
            ListTile(
              title: Text('Bicicletas disponibles'),
              leading: Radio(
                value: OrderBy.bikes,
                groupValue: _orderBy,
                onChanged: (OrderBy value) {
                  setState(() { _orderBy = value;  });
                  orderNearbyStationList();
                  Navigator.of(context).pop();
                },
              ),
            ),
            ListTile(
              title: Text('Espacios disponibles'),
              leading: Radio(
                value: OrderBy.slots,
                groupValue: _orderBy,
                onChanged: (OrderBy value) {
                  setState(() { _orderBy = value; });
                  orderNearbyStationList();
                  Navigator.of(context).pop();
                },
              ),
            ),
          ],
        ),
          ],
        ),
      ),
    );
  }
}
