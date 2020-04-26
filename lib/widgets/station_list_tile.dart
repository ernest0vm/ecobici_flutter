import 'package:ecobici/styles/my_colors.dart';
import 'package:flutter/material.dart';

class StationListTile extends StatefulWidget {

  final String id;
  final String name;
  final String address;
  final String distance;
  final String bikes;
  final String slots;

  StationListTile({
    this.id,
    this.name,
    this.address,
    this.distance,
    this.bikes,
    this.slots,
  });

  @override
  _StationListTileState createState() => _StationListTileState();
}

class _StationListTileState extends State<StationListTile> {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.all(Radius.circular(15)),
      ),
      padding: EdgeInsets.symmetric(vertical: 5),
      child: Column(
        children: <Widget>[
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Expanded(
                  child: Text(widget.name, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: MyColors.primaryColor),),
                ),
                Text("Estacion: " + widget.id),
              ],
            ),
          ),
          Container(
            alignment: Alignment.centerLeft,
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text("Direccion: " + widget.address.substring(6)),
                Text('Distancia: ${(double.parse(widget.distance) / 1000).toStringAsFixed(2)} km'),
              ],
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Icon(Icons.directions_bike, size: 20, color: MyColors.primaryColor),
                    Text(" " + widget.bikes + " bicicletas disponibles")
                  ],
                ),
              ),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Icon(Icons.local_parking, size: 20, color: MyColors.primaryColor),
                    Text(widget.slots + " espacios disponibles")
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
