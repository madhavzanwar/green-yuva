import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:url_launcher/url_launcher.dart';
import '../models/ecore.dart';
import '../theme/app_theme.dart';
import '../services/location_service.dart';

enum RadarMapDisplayMode {
  satellite,
  street,
  tacticalRadar,
}

/// Neo-Brutalist GreenRush Interactive Radar & Satellite Map.
/// Displays high-resolution satellite imagery (Esri World Imagery) and OpenStreetMap
/// with zero GPS keys required (Samarth / SchemeSetu inspired).
/// Includes interactive campus markers, live GPS distance calculation,
/// auto-locate positioning, and 1-tap Google Maps GPS turn-by-turn navigation.
class GreenRushRadarMap extends StatefulWidget {
  final List<Ecore> ecores;
  final gmaps.LatLng? userLocation;
  final Ecore? selectedEcore;
  final Function(Ecore ecore)? onEcoreTap;
  final bool isCompact;
  final VoidCallback? onOpenFullMap;
  final Function(gmaps.LatLng newLocation)? onLocationUpdated;

  const GreenRushRadarMap({
    Key? key,
    required this.ecores,
    this.userLocation,
    this.selectedEcore,
    this.onEcoreTap,
    this.isCompact = false,
    this.onOpenFullMap,
    this.onLocationUpdated,
  }) : super(key: key);

  @override
  State<GreenRushRadarMap> createState() => _GreenRushRadarMapState();
}

class _GreenRushRadarMapState extends State<GreenRushRadarMap>
    with SingleTickerProviderStateMixin {
  late AnimationController _sweepController;
  RadarMapDisplayMode _displayMode = RadarMapDisplayMode.satellite;
  final MapController _flutterMapController = MapController();
  late gmaps.LatLng _currentUserLocation;
  Ecore? _activeSelectedEcore;
  bool _isLocating = false;
  double _currentZoom = 13.5;

  @override
  void initState() {
    super.initState();
    _currentUserLocation = widget.userLocation ?? const gmaps.LatLng(18.5204, 73.8567);
    _activeSelectedEcore = widget.selectedEcore ?? (widget.ecores.isNotEmpty ? widget.ecores.first : null);
    _sweepController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void didUpdateWidget(covariant GreenRushRadarMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.userLocation != null && widget.userLocation != oldWidget.userLocation) {
      setState(() {
        _currentUserLocation = widget.userLocation!;
      });
      _moveMapTo(widget.userLocation!.latitude, widget.userLocation!.longitude);
    }
    if (widget.selectedEcore != null && widget.selectedEcore != oldWidget.selectedEcore) {
      setState(() {
        _activeSelectedEcore = widget.selectedEcore;
      });
      _moveMapTo(widget.selectedEcore!.latitude, widget.selectedEcore!.longitude, zoom: 15.0);
    }
  }

  void _moveMapTo(double lat, double lng, {double? zoom}) {
    final targetZoom = zoom ?? _currentZoom;
    try {
      _flutterMapController.move(ll.LatLng(lat, lng), targetZoom);
      _currentZoom = targetZoom;
    } catch (_) {}
  }

  Future<void> _triggerGpsRadar({bool showFeedback = true}) async {
    if (_isLocating) return;
    setState(() {
      _isLocating = true;
    });

    try {
      final pos = await LocationService.determinePosition();
      final newLatLng = gmaps.LatLng(pos.latitude, pos.longitude);
      if (mounted) {
        setState(() {
          _currentUserLocation = newLatLng;
          _isLocating = false;
        });

        widget.onLocationUpdated?.call(newLatLng);
        _moveMapTo(pos.latitude, pos.longitude, zoom: 15.5);

        if (showFeedback) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: AppColors.solidBlack,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: AppColors.electricMint, width: 2.0),
              ),
              content: Row(
                children: [
                  const Icon(Icons.gps_fixed_rounded, color: AppColors.electricMint, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'GPS Locked: ${newLatLng.latitude.toStringAsFixed(4)}° N, ${newLatLng.longitude.toStringAsFixed(4)}° E',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        fontSize: 12.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLocating = false;
        });
      }
    }
  }

  Ecore? _getNearestEcore() {
    if (widget.ecores.isEmpty) return null;
    Ecore? nearest;
    double minDistance = double.infinity;
    for (final ecore in widget.ecores) {
      final d = LocationService.calculateDistanceInMeters(
        _currentUserLocation.latitude,
        _currentUserLocation.longitude,
        ecore.latitude,
        ecore.longitude,
      );
      if (d < minDistance) {
        minDistance = d;
        nearest = ecore;
      }
    }
    return nearest;
  }

  String _getNearestHubText() {
    final nearest = _getNearestEcore();
    if (nearest == null) return 'No Active Hubs';
    final d = LocationService.calculateDistanceInMeters(
      _currentUserLocation.latitude,
      _currentUserLocation.longitude,
      nearest.latitude,
      nearest.longitude,
    );
    final distStr = LocationService.formatDistance(d);
    return 'Nearest: ${nearest.name} • $distStr';
  }

  Future<void> _openDirectionsInGoogleMaps(double lat, double lng) async {
    final url = 'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  void dispose() {
    _sweepController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_displayMode == RadarMapDisplayMode.tacticalRadar) {
      return _buildTacticalRadarView();
    }
    return _buildFlutterMapView();
  }

  Widget _buildFlutterMapView() {
    final isSatellite = _displayMode == RadarMapDisplayMode.satellite;
    final pos = _currentUserLocation;

    return Stack(
      children: [
        // 1. High Resolution Keyless Map (Esri Satellite or OpenStreetMap)
        FlutterMap(
          mapController: _flutterMapController,
          options: MapOptions(
            initialCenter: ll.LatLng(pos.latitude, pos.longitude),
            initialZoom: _currentZoom,
            minZoom: 3.0,
            maxZoom: 18.5,
            onTap: (tapPosition, point) {
              setState(() {
                _activeSelectedEcore = null;
              });
            },
          ),
          children: [
            TileLayer(
              urlTemplate: isSatellite
                  ? 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}'
                  : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.greenyuva.app',
              maxZoom: 19,
            ),

            // Markers Layer (User GPS Pin + All Campuses)
            MarkerLayer(
              markers: [
                // Real User Location Marker
                Marker(
                  point: ll.LatLng(pos.latitude, pos.longitude),
                  width: 50,
                  height: 50,
                  child: _buildUserLocationPin(),
                ),

                // College & University Markers
                ...widget.ecores.map((ecore) {
                  final isSelected = _activeSelectedEcore?.id == ecore.id;
                  final dist = LocationService.calculateDistanceInMeters(
                    pos.latitude,
                    pos.longitude,
                    ecore.latitude,
                    ecore.longitude,
                  );
                  final distStr = LocationService.formatDistance(dist);

                  return Marker(
                    point: ll.LatLng(ecore.latitude, ecore.longitude),
                    width: isSelected ? 150 : 130,
                    height: 56,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _activeSelectedEcore = ecore;
                        });
                        _moveMapTo(ecore.latitude, ecore.longitude, zoom: 15.5);
                        widget.onEcoreTap?.call(ecore);
                      },
                      child: _buildMapPinBadge(ecore, isSelected, distStr),
                    ),
                  );
                }),
              ],
            ),
          ],
        ),

        // 2. Top Bar: Coordinates Pill & Mode Switchers
        Positioned(
          top: 12,
          left: 14,
          right: 14,
          child: Row(
            children: [
              // GPS Status Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.pureWhite,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.solidBlack, width: 1.8),
                  boxShadow: const [
                    BoxShadow(
                      color: AppColors.solidBlack,
                      offset: Offset(2, 2),
                      blurRadius: 0,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _isLocating ? AppColors.butterYellow : AppColors.leafGreen,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _isLocating
                          ? 'Locating...'
                          : '${pos.latitude.toStringAsFixed(3)}°, ${pos.longitude.toStringAsFixed(3)}°',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.solidBlack,
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Locate Me GPS Button
              _buildGpsRadarButton(),
            ],
          ),
        ),

        // 3. Right Map Control Stack (Mode Toggle, Zoom, Re-center, All India)
        Positioned(
          top: 56,
          right: 14,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _buildViewModeTogglePill(),
              const SizedBox(height: 6),
              _buildTacticalRadarPill(),
              const SizedBox(height: 6),
              _buildCenterGpsButton(pos),
              const SizedBox(height: 6),
              _buildAllIndiaButton(),
              const SizedBox(height: 6),
              _buildZoomControls(),
            ],
          ),
        ),

        // 4. Selected College Bottom Drawer / Detail Card (Samarth Inspired)
        if (_activeSelectedEcore != null)
          Positioned(
            bottom: widget.isCompact ? 10 : 110,
            left: 14,
            right: 14,
            child: _buildCampusDetailBanner(_activeSelectedEcore!, pos),
          ),
      ],
    );
  }

  Widget _buildMapPinBadge(Ecore ecore, bool isSelected, String distStr) {
    final acronym = ecore.name.split('—').first.trim().split(' ').first;
    final pinColor = ecore.isConquered ? AppColors.electricMint : AppColors.butterYellow;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.dustyCoral : pinColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.solidBlack, width: isSelected ? 2.0 : 1.6),
            boxShadow: const [
              BoxShadow(
                color: AppColors.solidBlack,
                offset: Offset(2, 2),
                blurRadius: 0,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                ecore.isConquered ? Icons.eco_rounded : Icons.school_rounded,
                size: 11,
                color: AppColors.solidBlack,
              ),
              const SizedBox(width: 3),
              Flexible(
                child: Text(
                  acronym,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w900,
                    color: AppColors.solidBlack,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                decoration: BoxDecoration(
                  color: AppColors.cardWhite,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: AppColors.solidBlack, width: 0.8),
                ),
                child: Text(
                  distStr,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 8.0,
                    fontWeight: FontWeight.w800,
                    color: AppColors.solidBlack,
                  ),
                ),
              ),
            ],
          ),
        ),
        // Pin pointer triangle
        CustomPaint(
          size: const Size(8, 5),
          painter: _TrianglePainter(
            color: isSelected ? AppColors.dustyCoral : pinColor,
            borderColor: AppColors.solidBlack,
          ),
        ),
      ],
    );
  }

  Widget _buildCampusDetailBanner(Ecore ecore, gmaps.LatLng userPos) {
    final dist = LocationService.calculateDistanceInMeters(
      userPos.latitude,
      userPos.longitude,
      ecore.latitude,
      ecore.longitude,
    );
    final distStr = LocationService.formatDistance(dist);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.solidBlack, width: 2.2),
        boxShadow: const [
          BoxShadow(
            color: AppColors.solidBlack,
            offset: Offset(3, 4),
            blurRadius: 0,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: ecore.isConquered ? AppColors.electricMint : AppColors.softSky,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.solidBlack, width: 1.4),
                ),
                child: Text(
                  ecore.isConquered ? 'VERIFIED GREEN CELL' : 'CAMPUS HUB',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    color: AppColors.solidBlack,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.butterYellow,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.solidBlack, width: 1.0),
                ),
                child: Text(
                  '📍 $distStr',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w900,
                    color: AppColors.solidBlack,
                  ),
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _activeSelectedEcore = null;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: AppColors.paperCream,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.solidBlack, width: 1.2),
                  ),
                  child: const Icon(Icons.close_rounded, size: 14, color: AppColors.solidBlack),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            ecore.name,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13.5,
              fontWeight: FontWeight.w900,
              color: AppColors.solidBlack,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (ecore.conqueredBySchoolName != null)
            Text(
              ecore.conqueredBySchoolName!,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: Colors.black54,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          const SizedBox(height: 10),
          Row(
            children: [
              // Google Maps Directions (SchemeSetu / Samarth style)
              Expanded(
                child: GestureDetector(
                  onTap: () => _openDirectionsInGoogleMaps(ecore.latitude, ecore.longitude),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.butterYellow,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.solidBlack, width: 1.6),
                      boxShadow: const [
                        BoxShadow(
                          color: AppColors.solidBlack,
                          offset: Offset(2, 2),
                          blurRadius: 0,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.directions_rounded, size: 14, color: AppColors.solidBlack),
                        const SizedBox(width: 4),
                        Text(
                          'Get Directions ↗',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            color: AppColors.solidBlack,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Missions / Action Hub Button
              Expanded(
                child: GestureDetector(
                  onTap: () => widget.onEcoreTap?.call(ecore),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.electricMint,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.solidBlack, width: 1.6),
                      boxShadow: const [
                        BoxShadow(
                          color: AppColors.solidBlack,
                          offset: Offset(2, 2),
                          blurRadius: 0,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.bolt_rounded, size: 14, color: AppColors.solidBlack),
                        const SizedBox(width: 4),
                        Text(
                          'Start Quests (${ecore.missions.length})',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            color: AppColors.solidBlack,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGpsRadarButton() {
    return GestureDetector(
      onTap: () => _triggerGpsRadar(showFeedback: true),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
        decoration: BoxDecoration(
          color: _isLocating ? AppColors.butterYellow : AppColors.electricMint,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.solidBlack, width: 2.0),
          boxShadow: const [
            BoxShadow(
              color: AppColors.solidBlack,
              offset: Offset(2, 2),
              blurRadius: 0,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _isLocating
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: AppColors.solidBlack,
                    ),
                  )
                : const Icon(Icons.gps_fixed_rounded, size: 15, color: AppColors.solidBlack),
            const SizedBox(width: 5),
            Text(
              _isLocating ? 'Locating...' : 'GPS Radar',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: AppColors.solidBlack,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildViewModeTogglePill() {
    final isSatellite = _displayMode == RadarMapDisplayMode.satellite;
    return GestureDetector(
      onTap: () {
        setState(() {
          _displayMode = isSatellite ? RadarMapDisplayMode.street : RadarMapDisplayMode.satellite;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSatellite ? AppColors.butterYellow : AppColors.pureWhite,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.solidBlack, width: 1.8),
          boxShadow: const [
            BoxShadow(
              color: AppColors.solidBlack,
              offset: Offset(2, 2),
              blurRadius: 0,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSatellite ? Icons.satellite_alt_rounded : Icons.map_rounded,
              size: 13,
              color: AppColors.solidBlack,
            ),
            const SizedBox(width: 4),
            Text(
              isSatellite ? '🛰️ Satellite' : '🗺️ Street Map',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                color: AppColors.solidBlack,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTacticalRadarPill() {
    return _buildMapModeToggle();
  }

  Widget _buildMapModeToggle() {
    final isRadar = _displayMode == RadarMapDisplayMode.tacticalRadar;
    return GestureDetector(
      onTap: () {
        setState(() {
          _displayMode = isRadar ? RadarMapDisplayMode.satellite : RadarMapDisplayMode.tacticalRadar;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isRadar ? AppColors.butterYellow : AppColors.electricMint,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.solidBlack, width: 1.8),
          boxShadow: const [
            BoxShadow(
              color: AppColors.solidBlack,
              offset: Offset(2, 2),
              blurRadius: 0,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isRadar ? Icons.satellite_alt_rounded : Icons.radar_rounded,
              size: 13,
              color: AppColors.solidBlack,
            ),
            const SizedBox(width: 4),
            Text(
              isRadar ? '🛰️ Satellite Map' : '🎯 Cyber Radar',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                color: AppColors.solidBlack,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCenterGpsButton(gmaps.LatLng pos) {
    return GestureDetector(
      onTap: () {
        _moveMapTo(pos.latitude, pos.longitude, zoom: 15.5);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.softSky,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.solidBlack, width: 1.8),
          boxShadow: const [
            BoxShadow(
              color: AppColors.solidBlack,
              offset: Offset(2, 2),
              blurRadius: 0,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.my_location_rounded, size: 13, color: AppColors.solidBlack),
            const SizedBox(width: 4),
            Text(
              'My Campus',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                color: AppColors.solidBlack,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAllIndiaButton() {
    return GestureDetector(
      onTap: () {
        _moveMapTo(21.0, 78.5, zoom: 4.8);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.paperCream,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.solidBlack, width: 1.8),
          boxShadow: const [
            BoxShadow(
              color: AppColors.solidBlack,
              offset: Offset(2, 2),
              blurRadius: 0,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.public_rounded, size: 13, color: AppColors.solidBlack),
            const SizedBox(width: 4),
            Text(
              'All India',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                color: AppColors.solidBlack,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildZoomControls() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.solidBlack, width: 1.8),
        boxShadow: const [
          BoxShadow(
            color: AppColors.solidBlack,
            offset: Offset(2, 2),
            blurRadius: 0,
          ),
        ],
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: () {
              final newZoom = math.min(18.5, _currentZoom + 1.0);
              _moveMapTo(_currentUserLocation.latitude, _currentUserLocation.longitude, zoom: newZoom);
            },
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Icon(Icons.add_rounded, size: 16, color: AppColors.solidBlack),
            ),
          ),
          Container(height: 1, width: 22, color: AppColors.solidBlack),
          GestureDetector(
            onTap: () {
              final newZoom = math.max(3.0, _currentZoom - 1.0);
              _moveMapTo(_currentUserLocation.latitude, _currentUserLocation.longitude, zoom: newZoom);
            },
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Icon(Icons.remove_rounded, size: 16, color: AppColors.solidBlack),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTacticalRadarView() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;

        return Stack(
          children: [
            // Base Radar Canvas (Terrain, Grid, River, Concentric Rings, Radar Sweep)
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _sweepController,
                builder: (context, child) {
                  return CustomPaint(
                    painter: _TacticalRadarPainter(
                      sweepAngle: _sweepController.value * 2 * math.pi,
                      isCompact: widget.isCompact,
                    ),
                  );
                },
              ),
            ),

            // Interactive Ecore Pins
            ...widget.ecores.asMap().entries.map((entry) {
              final idx = entry.key;
              final ecore = entry.value;

              // Normalized pin coordinates across canvas
              final pinOffsets = [
                const Offset(0.24, 0.32), // PCCOE Green Hub
                const Offset(0.68, 0.28), // VIT Solar
                const Offset(0.42, 0.72), // COEP Hydro
                const Offset(0.78, 0.65), // PICT Tech Core
                const Offset(0.22, 0.76), // MIT-WPU Eco
                const Offset(0.55, 0.40), // VIIT Clean Stream
                const Offset(0.82, 0.38), // BITS Renewable
                const Offset(0.35, 0.20), // VIT Vellore Air
              ];

              final offsetRatio = pinOffsets[idx % pinOffsets.length];
              final dx = offsetRatio.dx * width;
              final dy = offsetRatio.dy * height;

              final isSelected = widget.selectedEcore?.id == ecore.id;

              return Positioned(
                left: dx - (widget.isCompact ? 36 : 46),
                top: dy - (widget.isCompact ? 28 : 34),
                child: GestureDetector(
                  onTap: () {
                    if (widget.onEcoreTap != null) {
                      widget.onEcoreTap!(ecore);
                    } else if (widget.onOpenFullMap != null) {
                      widget.onOpenFullMap!();
                    }
                  },
                  child: _buildEcorePinWidget(ecore, isSelected),
                ),
              );
            }),

            // User GPS Location Pin (Center-slanted)
            Positioned(
              left: (width * 0.48) - 18,
              top: (height * 0.48) - 18,
              child: _buildUserLocationPin(),
            ),

            // Top-Left Coordinates Pill
            if (!widget.isCompact)
              Positioned(
                top: 12,
                left: 14,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.pureWhite,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.solidBlack, width: 1.8),
                    boxShadow: const [
                      BoxShadow(
                        color: AppColors.solidBlack,
                        offset: Offset(2, 2),
                        blurRadius: 0,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _isLocating ? AppColors.butterYellow : AppColors.leafGreen,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _isLocating
                            ? 'GPS Scanning...'
                            : 'GPS: ${_currentUserLocation.latitude.toStringAsFixed(4)}°, ${_currentUserLocation.longitude.toStringAsFixed(4)}°',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.solidBlack,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Top-Right Controls (GPS Radar button & Toggle)
            if (!widget.isCompact)
              Positioned(
                top: 12,
                right: 12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _buildGpsRadarButton(),
                    const SizedBox(height: 6),
                    _buildMapModeToggle(),
                  ],
                ),
              ),

            // Bottom Radar Info Pill (Full map mode - Clickable for GPS)
            if (!widget.isCompact)
              Positioned(
                bottom: 160,
                left: 14,
                child: GestureDetector(
                  onTap: () async {
                    final nearest = _getNearestEcore();
                    if (nearest != null) {
                      final url = 'https://www.google.com/maps/dir/?api=1&destination=${nearest.latitude},${nearest.longitude}';
                      final uri = Uri.parse(url);
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                      }
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.pureWhite.withValues(alpha: 0.94),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.solidBlack, width: 1.6),
                      boxShadow: const [
                        BoxShadow(
                          color: AppColors.solidBlack,
                          offset: Offset(2, 2),
                          blurRadius: 0,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.near_me_rounded, size: 14, color: AppColors.solidBlack),
                        const SizedBox(width: 6),
                        Text(
                          '${_getNearestHubText()} • Tap for GPS ↗',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            color: AppColors.solidBlack,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildUserLocationPin() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF0066FF).withValues(alpha: 0.25),
            border: Border.all(color: const Color(0xFF0066FF), width: 1.5),
          ),
          child: Center(
            child: Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF0066FF),
                border: Border.all(color: Colors.white, width: 2.2),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    offset: Offset(0, 1.5),
                    blurRadius: 3,
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 2),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.solidBlack,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            'YOU (GPS)',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 8,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEcorePinWidget(Ecore ecore, bool isSelected) {
    final pinColor = ecore.isConquered ? AppColors.electricMint : AppColors.butterYellow;
    final icon = ecore.isConquered ? Icons.eco_rounded : Icons.bolt_rounded;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(
            horizontal: isSelected ? 8 : 6,
            vertical: isSelected ? 4 : 3,
          ),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.dustyCoral : pinColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: AppColors.solidBlack,
              width: isSelected ? 2.0 : 1.5,
            ),
            boxShadow: const [
              BoxShadow(
                color: AppColors.solidBlack,
                offset: Offset(1.5, 2.0),
                blurRadius: 0,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 12, color: AppColors.solidBlack),
              const SizedBox(width: 3),
              Text(
                ecore.name.split(' ').first,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w900,
                  color: AppColors.solidBlack,
                ),
              ),
            ],
          ),
        ),
        // Pin pointer triangle
        CustomPaint(
          size: const Size(10, 6),
          painter: _TrianglePainter(
            color: isSelected ? AppColors.dustyCoral : pinColor,
            borderColor: AppColors.solidBlack,
          ),
        ),
      ],
    );
  }
}

class _TrianglePainter extends CustomPainter {
  final Color color;
  final Color borderColor;

  _TrianglePainter({required this.color, required this.borderColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();

    canvas.drawPath(path, paint);
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Custom Canvas Painter for Tactical Neo-Brutalist Radar Map
class _TacticalRadarPainter extends CustomPainter {
  final double sweepAngle;
  final bool isCompact;

  _TacticalRadarPainter({
    required this.sweepAngle,
    required this.isCompact,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.48, size.height * 0.48);

    // 1. Base Land Background (Soft Carto Warm Sage)
    final bgPaint = Paint()..color = const Color(0xFFEAF1EB);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // 2. Soft Green Ecological Zones (Parks / Reserves)
    final parkPaint = Paint()
      ..color = const Color(0xFFD3E7D5)
      ..style = PaintingStyle.fill;

    // North-West Green Reserve
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.08, size.height * 0.12, size.width * 0.28, size.height * 0.32),
        const Radius.circular(16),
      ),
      parkPaint,
    );

    // South-East Green Campus Belt
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.60, size.height * 0.55, size.width * 0.32, size.height * 0.35),
        const Radius.circular(20),
      ),
      parkPaint,
    );

    // 3. Water Body / River Bend (Mutha River curve)
    final riverPaint = Paint()
      ..color = const Color(0xFFC3E0FA)
      ..style = PaintingStyle.stroke
      ..strokeWidth = isCompact ? 16 : 24
      ..strokeCap = StrokeCap.round;

    final riverPath = Path()
      ..moveTo(0, size.height * 0.35)
      ..cubicTo(
        size.width * 0.35,
        size.height * 0.25,
        size.width * 0.55,
        size.height * 0.70,
        size.width,
        size.height * 0.60,
      );
    canvas.drawPath(riverPath, riverPaint);

    // River subtle border
    final riverBorder = Paint()
      ..color = const Color(0xFF90C2EE)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawPath(riverPath, riverBorder);

    // 4. Street Grid & Campus Transit Roads
    final roadPaint = Paint()
      ..color = const Color(0xFFFFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = isCompact ? 3.5 : 5.0;

    final roadBorder = Paint()
      ..color = const Color(0xFFCAD7CE)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Horizontal Primary Arteries
    for (double dy in [0.22, 0.48, 0.75]) {
      final y = size.height * dy;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), roadPaint);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), roadBorder);
    }

    // Vertical Arteries
    for (double dx in [0.25, 0.50, 0.78]) {
      final x = size.width * dx;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), roadPaint);
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), roadBorder);
    }

    // Diagonal Campus Avenue
    canvas.drawLine(
      Offset(size.width * 0.1, size.height * 0.8),
      Offset(size.width * 0.9, size.height * 0.2),
      roadPaint,
    );

    // 5. Tactical Concentric Radar Rings
    final ringPaint = Paint()
      ..color = const Color(0xFF2E7D32).withValues(alpha: 0.20)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final maxRadius = math.min(size.width, size.height) * 0.45;
    for (int i = 1; i <= 3; i++) {
      final r = maxRadius * (i / 3.0);
      canvas.drawCircle(center, r, ringPaint);
    }

    // Radar Crosshairs
    final crossPaint = Paint()
      ..color = const Color(0xFF2E7D32).withValues(alpha: 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawLine(
      Offset(center.dx - maxRadius, center.dy),
      Offset(center.dx + maxRadius, center.dy),
      crossPaint,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy - maxRadius),
      Offset(center.dx, center.dy + maxRadius),
      crossPaint,
    );

    // 6. Rotating Animated Radar Sweep Beam
    final sweepPaint = Paint()
      ..shader = SweepGradient(
        center: FractionalOffset(center.dx / size.width, center.dy / size.height),
        startAngle: 0.0,
        endAngle: math.pi / 2,
        colors: [
          const Color(0xFF00E676).withValues(alpha: 0.28),
          const Color(0xFF00E676).withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: maxRadius))
      ..style = PaintingStyle.fill;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(sweepAngle);
    canvas.drawCircle(Offset.zero, maxRadius, sweepPaint);

    // Leading sweep line
    final linePaint = Paint()
      ..color = const Color(0xFF00C853).withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;
    canvas.drawLine(Offset.zero, Offset(maxRadius, 0), linePaint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _TacticalRadarPainter oldDelegate) {
    return oldDelegate.sweepAngle != sweepAngle;
  }
}
