import 'package:english_words/english_words.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';//googleMap
import 'package:google_maps_flutter/google_maps_flutter.dart';//googleMap
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MyAppState(),
      child: MaterialApp(
        title: 'Namer App',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
        ),
        home: MyHomePage(),
      ),
    );
  }
}

class MyAppState extends ChangeNotifier {
  var current = WordPair.random();

  void getNext(){
    current = WordPair.random();
    notifyListeners();
  }

  var favorites = <WordPair>[];

  void toggleFavorite(){
    if(favorites.contains(current)){
      favorites.remove(current);
    } else {
      favorites.add(current);
    }
  }
}

// ...

class MyHomePage extends StatefulWidget {
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  var selectedIndex = 0;

  @override
  Widget build(BuildContext context) {

    Widget page;
    switch (selectedIndex){
      case 0:
        page = GeneratorPage();
        break;
      case 1:
        page = FavoritesPage();
        break;
      case 2:
        page = GoogleMapPage();
        break;
      default:
        throw UnimplementedError('no widget for $selectedIndex');
    }




    return LayoutBuilder(
      builder: (context, constraints) {
        return Scaffold(
          body: Row(
            children: [
              SafeArea(
                child: NavigationRail(
                  extended: constraints.maxWidth >= 600,
                  destinations: [
                    NavigationRailDestination(
                      icon: Icon(Icons.home),
                      label: Text('Home'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.favorite),
                      label: Text('Favorites'),
                    ),
                    NavigationRailDestination(     //追加課題で
                      icon: Icon(Icons.map),
                      label: Text("Googlemap"),
                    ),
                  ],
                  selectedIndex: selectedIndex,
                  onDestinationSelected: (value) {
                    setState(() {
                      selectedIndex = value;
                    });
                  },
                ),
              ),
              Expanded(
                child: Container(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  child: page,
                ),
              ),
            ],
          ),
        );
      }
    );
  }
}

class GoogleMapPage extends StatefulWidget {
  @override
  GoogleMapPageState createState() => GoogleMapPageState();
}

class GoogleMapPageState extends State<GoogleMapPage> {//GooglemapPage extends StatelessWidget
  //状態管理
  late GoogleMapController mapController;
  final LatLng _center = const LatLng(35.4750768, 133.05074);//45.521563, -122.677433
  String apiKey = "";
  List<Marker> markers = [];
  int selectedRadius = 0;//5km
  List<Map<String, dynamic>> places = [];

  //API取得・・・・・・・・・・・・・・・・・・・・・・
  @override
  void initState() {
    super.initState();
    _fetchApiKey();
  }
  //API取得関数
  Future<void> _fetchApiKey() async {
    final response = await http.get(Uri.parse('http://localhost:3000/google_places_api_key'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        apiKey = data['apiKey'] ?? "";

        if (apiKey.isNotEmpty) {
          _getNearbyCafes(selectedRadius); // APIキーを取得した後にカフェを検索
        } else {
          throw Exception('API key is null or empty');
        }
      });
    } else {
      throw Exception('Failed to load API key');
    }
  }//..................................................

  //検索
  Future<void> _getNearbyCafes(int radius) async {
    if (apiKey.isEmpty) return; // APIキーが取得されていない場合はリターン
    final url = 'http://localhost:3000/nearby-cafes?lat=${_center.latitude}&lng=${_center.longitude}&radius=$radius';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final results = data['results'];
      setState(() {
        markers = results.map<Marker>((place) {
          final location = place['geometry']['location'];

          return Marker(
            markerId: MarkerId(place['place_id']),
            position: LatLng(location['lat'], location['lng']),
            infoWindow: InfoWindow(
              title: place['name'],
              snippet: place['vicinity'],
              onTap: () {
                _showPlaceDetails(place);
              },
            ),
          );
        }).toList();

        if(results.isNotEmpty){
          places = List<Map<String, dynamic>>.from(results);
          print(places);
        }
      });
    } else {
      throw Exception('Failed to load nearby cafes');
    }
  }

  void _showPlaceDetails(Map<String, dynamic> place) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(place['name']),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Address: ${place['vicinity']}'),
              Text('Rating: ${place['rating'] ?? 'N/A'}'),
            ],
          ),
          actions: [
            TextButton(
              child: Text('Close'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }


  Widget listView(List<Map<String, dynamic>> places){
    return ListView.builder(
      itemCount: places.length,

      itemBuilder: (context, index){
        final place = places[index];
        return ListTile(
          title: Text(place["name"] ?? 'N/A'),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start ,
            children: [
               Text('Address: ${place['vicinity'] ?? 'N/A'}'),
               Text('Rating: ${place['rating'] ?? 'N/A'}'),
               Text('Opening Hours: ${place['opening_hours'] ?? 'N/A'}'),
            ],
          ),
        );
      },
    );
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('周辺のカフェ'),
          backgroundColor: Colors.green[700],
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: DropdownButton<int>(
                value: selectedRadius,
                items: [
                  DropdownMenuItem(value: 0, child: Text("0km")),
                  DropdownMenuItem(value: 1000, child: Text('1km')),
                  DropdownMenuItem(value: 2000, child: Text('2km')),
                  DropdownMenuItem(value: 3000, child: Text('3km')),
                  DropdownMenuItem(value: 4000, child: Text('4km')),
                  DropdownMenuItem(value: 5000, child: Text('5km')),
                ],
                onChanged: (value) {
                  setState(() {
                    selectedRadius = value!;
                    _getNearbyCafes(selectedRadius);
                  });
                },
              ),
            ),
            Expanded(
              child: GoogleMap(
                onMapCreated: _onMapCreated,
                initialCameraPosition: CameraPosition(
                  target: _center,
                  zoom: 14.0,
                ),
                markers: Set<Marker>.of(markers),
              ),
            ),
            Expanded(
              child: places.isNotEmpty ? listView(places) : Center(child: Text('データがないよ')),
            ),
          ],
        ),
      ),
    );
  }
}

// ...

class FavoritesPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();

    if (appState.favorites.isEmpty) {
      return Center(
        child: Text('No favorites yet.'),
      );
    }

    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.all(20),
          child: Text('You have '
              '${appState.favorites.length} favorites:'),
        ),
        for (var pair in appState.favorites)
          ListTile(
            leading: Icon(Icons.favorite),
            title: Text(pair.asLowerCase),
          ),
      ],
    );
  }
}

class GeneratorPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    var pair = appState.current;

    IconData icon;
    if (appState.favorites.contains(pair)) {
      icon = Icons.favorite;
    } else {
      icon = Icons.favorite_border;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          //Image.asset("../images/son.jpg"),
          BigCard(pair: pair),
          SizedBox(height: 10),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  appState.toggleFavorite();
                },
                icon: Icon(icon),
                label: Text('Like'),
              ),
              SizedBox(width: 10),
              ElevatedButton(
                onPressed: () {
                  appState.getNext();
                },
                child: Text('Next'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}




// ...

class BigCard extends StatelessWidget {
  const BigCard({
    super.key,
    required this.pair,
  });

  final WordPair pair;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final style = theme.textTheme.displayMedium!.copyWith(
      color: theme.colorScheme.onPrimary,
    );

    return Card(
      color: theme.colorScheme.primary,
      child: Padding(
        padding: const EdgeInsets.all(20.0),

        child: Text(
          pair.asLowerCase,
          style: style,
          semanticsLabel: "${pair.first} ${pair.second}",
          ),
      ),
    );
  }
}
