/// id : "1"
/// district : "CUA"
/// lon : "-99.1678091"
/// lat : "19.4335714"
/// bikes : "21"
/// slots : "5"
/// zip : "06500"
/// address : "001 - Río Sena-Río Balsas"
/// addressNumber : "S/N"
/// nearbyStations : "3,8,85"
/// status : "OPN"
/// name : "1 RIO SENA-RIO BALSAS"
/// stationType : "BIKE,TPV"
/// distance : "1500m"

class Station {
  int id;
  String district;
  String lon;
  String lat;
  int bikes;
  int slots;
  String zip;
  String address;
  String addressNumber;
  String nearbyStations;
  String status;
  String name;
  String stationType;
  double distance;

  static Station fromMap(Map<String, dynamic> map) {
    if (map == null) return null;
    Station station = Station();
    station.id = int.parse(map['id']);
    station.district = map['district'];
    station.lon = map['lon'];
    station.lat = map['lat'];
    station.bikes = int.parse(map['bikes']);
    station.slots = int.parse(map['slots']);
    station.zip = map['zip'];
    station.address = map['address'];
    station.addressNumber = map['addressNumber'];
    station.nearbyStations = map['nearbyStations'];
    station.status = map['status'];
    station.name = map['name'];
    station.stationType = map['stationType'];
    return station;
  }

  Map toJson() => {
    "id": id,
    "district": district,
    "lon": lon,
    "lat": lat,
    "bikes": bikes,
    "slots": slots,
    "zip": zip,
    "address": address,
    "addressNumber": addressNumber,
    "nearbyStations": nearbyStations,
    "status": status,
    "name": name,
    "stationType": stationType,
    "distance": distance,
  };
}