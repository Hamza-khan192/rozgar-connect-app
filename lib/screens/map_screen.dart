import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../models/labor_profile.dart';
import '../providers/data_provider.dart';
import '../widgets/app_page_route.dart';
import 'laborer_detail_screen.dart';

/// Live map for customers: your position plus laborers who shared
/// their live location. Tap a pin for details.
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  static const _mardan = LatLng(34.2019, 72.0525);

  LatLng? _me;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final data = context.read<DataProvider>();
    LatLng? me;
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm != LocationPermission.denied &&
          perm != LocationPermission.deniedForever &&
          await Geolocator.isLocationServiceEnabled()) {
        final pos = await Geolocator.getCurrentPosition(
            locationSettings:
                const LocationSettings(accuracy: LocationAccuracy.medium));
        me = LatLng(pos.latitude, pos.longitude);
      }
    } catch (_) {
      // No GPS — fall back to Mardan center.
    }
    try {
      await data.loadLatestLocations();
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      _me = me;
      _loading = false;
    });
  }

  String _distanceLabel(LatLng to) {
    if (_me == null) return '';
    final km = const Distance().as(LengthUnit.Kilometer, _me!, to);
    return ' • ${km.toStringAsFixed(1)} km away';
  }

  void _showSheet(LaborProfile p) {
    final data = context.read<DataProvider>();
    final loc = data.latestLocations[p.laborId];
    final point = loc?.latitude == null
        ? null
        : LatLng(loc!.latitude!, loc.longitude!);
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(data.laborerName(p),
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(
                '${data.skillNamesFor(p.laborId).take(3).join(' • ')}${point == null ? '' : _distanceLabel(point)}'),
            const SizedBox(height: 4),
            Text(
              p.dailyWage == null
                  ? 'Wage on request'
                  : 'Rs ${p.dailyWage!.toStringAsFixed(0)}/day',
              style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  Navigator.of(context).push(AppPageRoute(
                      builder: (_) =>
                          LaborerDetailScreen(laborId: p.laborId)));
                },
                child: const Text('View profile'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<DataProvider>();
    final center = _me ?? _mardan;

    final markers = <Marker>[];
    if (_me != null) {
      markers.add(Marker(
        point: _me!,
        width: 52,
        height: 52,
        child: const Icon(Icons.person_pin_circle,
            color: Colors.blue, size: 46),
      ));
    }
    for (final p in data.laborers) {
      final loc = data.latestLocations[p.laborId];
      if (loc?.latitude == null || loc?.longitude == null) continue;
      final point = LatLng(loc!.latitude!, loc.longitude!);
      markers.add(Marker(
        point: point,
        width: 52,
        height: 52,
        child: GestureDetector(
          onTap: () => _showSheet(p),
          child: Stack(
            alignment: Alignment.center,
            children: [
              const Icon(Icons.location_on, color: Colors.teal, size: 46),
              Positioned(
                top: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: const [
                      BoxShadow(blurRadius: 3, color: Colors.black26)
                    ],
                  ),
                  child: Text(
                    data.laborerName(p).split(' ').first,
                    style: const TextStyle(
                        fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nearby Laborers'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh locations',
            onPressed: () {
              setState(() => _loading = true);
              _init();
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : markers.length <= 1 && _me == null
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Text(
                      'Kisi laborer ne abhi live location share nahi ki.\nLaborer "Update Location" dabaye to wo yahan nazar aayega.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : FlutterMap(
                  options: MapOptions(
                    initialCenter: center,
                    initialZoom: 13,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.rozgar.connect',
                    ),
                    MarkerLayer(markers: markers),
                  ],
                ),
    );
  }
}
