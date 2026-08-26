import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../providers/transit_provider.dart';
import '../providers/language_provider.dart';
import '../providers/settings_provider.dart';
import '../models/bus_stop_model.dart';
import '../models/bus_model.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  // ============================================================
  // SMART PLAN STATE
  // ============================================================

  bool _showSmartPlan = false;
  bool _showResults = false;

  BusStop? _fromStop;
  BusStop? _toStop;
  TimeOfDay? _arrivalTime;

  List<Bus> _matchingBuses = [];

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TransitProvider>(context);
    final langProvider = Provider.of<LanguageProvider>(context);
    final settingsProvider =
        Provider.of<SettingsProvider>(context);

    final isDarkMode =
        Theme.of(context).brightness == Brightness.dark;

    const centerLatLng = LatLng(23.7561, 90.3872);
    const userLocation = LatLng(23.7522, 90.3938);

    final baseTileLayer = TileLayer(
      urlTemplate:
          'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}@2x.png',
      subdomains: const ['a', 'b', 'c', 'd'],
      userAgentPackageName: 'com.example.dhaka_bus_tracker',
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          langProvider.t('Dhaka Bus Tracker'),
          style: const TextStyle(
            color: Colors.white,
          ),
        ),
        backgroundColor:
            Theme.of(context).colorScheme.primary,
        elevation: 0,

        // ========================================================
        // SMART PLAN BUTTON
        // ========================================================

        actions: [
          IconButton(
            tooltip: 'Smart Trip Planner',
            icon: const Icon(
              Icons.route,
              color: Colors.white,
            ),
            onPressed: () {
              setState(() {
                _showSmartPlan = !_showSmartPlan;

                if (!_showSmartPlan) {
                  _showResults = false;
                }
              });
            },
          ),
        ],
      ),

      // ==========================================================
      // BODY
      // ==========================================================

      body: provider.isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : Stack(
              children: [

                // ==================================================
                // MAP
                // ==================================================

                FlutterMap(
                  options: MapOptions(
                    initialCenter: centerLatLng,
                    initialZoom: 13.0,
                    onTap: (_, __) {
                      provider.clearStopSelection();
                    },
                  ),
                  children: [

                    // =================================================
                    // MAP TILE
                    // =================================================

                    isDarkMode
                        ? ColorFiltered(
                            colorFilter:
                                const ColorFilter.matrix([
                              -1, 0, 0, 0, 255,
                              0, -1, 0, 0, 255,
                              0, 0, -1, 0, 255,
                              0, 0, 0, 1, 0,
                            ]),
                            child: baseTileLayer,
                          )
                        : baseTileLayer,

                    // =================================================
                    // SELECTED BUS ROUTE
                    // =================================================

                    PolylineLayer<Object>(
                      polylines: [
                        if (provider.selectedBus != null)
                          Polyline<Object>(
                            points: provider
                                .getSelectedRouteCoordinates(),
                            color: Colors.blueAccent
                                .withOpacity(0.7),
                            strokeWidth: 4.5,
                            pattern:
                                const StrokePattern.dotted(),
                          ),
                      ],
                    ),

                    // =================================================
                    // MARKERS
                    // =================================================

                    MarkerLayer(
                      markers: [

                        // USER LOCATION
                        if (settingsProvider.locationAccess)
                          Marker(
                            point: userLocation,
                            width: 45,
                            height: 45,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.blue
                                    .withOpacity(0.2),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.blue
                                      .withOpacity(0.5),
                                  width: 1,
                                ),
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.my_location,
                                  color:
                                      Colors.blueAccent,
                                  size: 24,
                                ),
                              ),
                            ),
                          ),

                        // BUS STOPS
                        ...provider.stops.map(
                          (stop) => Marker(
                            point: LatLng(
                              stop.lat,
                              stop.lng,
                            ),
                            width: 30,
                            height: 30,
                            child: GestureDetector(
                              onTap: () {
                                provider.selectStop(stop);

                                _showArrivalsBottomSheet(
                                  context,
                                  stop,
                                  provider,
                                  langProvider,
                                );
                              },
                              child: Container(
                                decoration:
                                    BoxDecoration(
                                  color: const Color(
                                    0xFF00B159,
                                  ),
                                  shape:
                                      BoxShape.circle,
                                  border:
                                      Border.all(
                                    color: Colors.black
                                        .withOpacity(0.5),
                                    width: 1.5,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.directions_bus,
                                  color: Colors.white,
                                  size: 15,
                                ),
                              ),
                            ),
                          ),
                        ),

                        // SELECTED BUS
                        if (provider.selectedBus != null)
                          Marker(
                            point: LatLng(
                              provider.selectedBus!
                                  .currentLat,
                              provider.selectedBus!
                                  .currentLng,
                            ),
                            width: 46,
                            height: 46,
                            child: Container(
                              decoration:
                                  BoxDecoration(
                                color: Colors
                                    .orangeAccent
                                    .shade700,
                                shape:
                                    BoxShape.circle,
                                border:
                                    Border.all(
                                  color: Colors.white,
                                  width: 2.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black
                                        .withOpacity(0.35),
                                    blurRadius: 6,
                                    offset:
                                        const Offset(
                                      0,
                                      3,
                                    ),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.directions_bus,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),

                // ==================================================
                // SMART PLAN PANEL
                // ==================================================

                if (_showSmartPlan)
                  Positioned(
                    top: 12,
                    left: 12,
                    right: 12,
                    child: _buildSmartPlanPanel(
                      context,
                      provider,
                    ),
                  ),

                // ==================================================
                // SELECTED BUS CARD
                // ==================================================

                if (provider.selectedBus != null &&
                    !_showResults)
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 20,
                    child: _buildSelectedBusCard(
                      provider,
                      langProvider,
                    ),
                  ),
              ],
            ),
    );
  }

  // ============================================================
  // SMART PLAN PANEL
  // ============================================================

  Widget _buildSmartPlanPanel(
    BuildContext context,
    TransitProvider provider,
  ) {
    return Material(
      elevation: 8,
      borderRadius:
          BorderRadius.circular(18),
      child: Container(
        constraints:
            const BoxConstraints(
          maxHeight: 600,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius:
              BorderRadius.circular(18),
        ),
        child: SingleChildScrollView(
          padding:
              const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [

              // ====================================================
              // HEADER
              // ====================================================

              Row(
                children: [

                  Container(
                    padding:
                        const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.psychology,
                      color: Theme.of(context)
                          .colorScheme
                          .primary,
                    ),
                  ),

                  const SizedBox(width: 9),

                  const Expanded(
                    child: Text(
                      'Smart Trip Planner',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ),

                  IconButton(
                    padding:
                        EdgeInsets.zero,
                    constraints:
                        const BoxConstraints(),
                    icon: const Icon(
                      Icons.close,
                    ),
                    onPressed: () {
                      setState(() {
                        _showSmartPlan = false;
                        _showResults = false;
                      });
                    },
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // ====================================================
              // FROM
              // ====================================================

              _buildStopDropdown(
                context: context,
                title: 'From',
                icon: Icons.my_location,
                value: _fromStop,
                stops: provider.stops,
                onChanged: (value) {
                  setState(() {
                    _fromStop = value;
                    _showResults = false;
                  });
                },
              ),

              const SizedBox(height: 8),

              // ====================================================
              // TO
              // ====================================================

              _buildStopDropdown(
                context: context,
                title: 'To',
                icon: Icons.location_on,
                value: _toStop,
                stops: provider.stops,
                onChanged: (value) {
                  setState(() {
                    _toStop = value;
                    _showResults = false;
                  });
                },
              ),

              const SizedBox(height: 8),

              // ====================================================
              // ARRIVAL TIME
              // ====================================================

              Card(
                margin: EdgeInsets.zero,
                child: ListTile(
                  dense: true,
                  leading: const Icon(
                    Icons.access_time,
                  ),
                  title: const Text(
                    'Arrive by',
                    style: TextStyle(
                      fontWeight:
                          FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    _arrivalTime == null
                        ? 'Select arrival time'
                        : _arrivalTime!
                            .format(context),
                  ),
                  trailing: const Icon(
                    Icons.keyboard_arrow_down,
                  ),
                  onTap: _selectArrivalTime,
                ),
              ),

              const SizedBox(height: 10),

              // ====================================================
              // PLAN BUTTON
              // ====================================================

              SizedBox(
                width: double.infinity,
                height: 45,
                child: ElevatedButton.icon(
                  onPressed: () {
                    _planTrip(provider);
                  },
                  icon: const Icon(
                    Icons.route,
                  ),
                  label: const Text(
                    'PLAN MY TRIP',
                    style: TextStyle(
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ),
              ),

              // ====================================================
              // RESULTS
              // ====================================================

              if (_showResults) ...[
                const SizedBox(height: 12),

                const Divider(),

                const SizedBox(height: 8),

                if (_matchingBuses.isEmpty)
                  _buildNoResultCard()
                else ...[
                  const Text(
                    'Smart Recommendations',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // FASTEST
                  _buildRecommendationCard(
                    title: 'FASTEST',
                    icon: Icons.bolt,
                    iconColor: Colors.orange,
                    bus: _getFastestBus(),
                  ),

                  const SizedBox(height: 8),

                  // CHEAPEST
                  _buildRecommendationCard(
                    title: 'CHEAPEST',
                    icon: Icons.payments,
                    iconColor: Colors.green,
                    bus: _getCheapestBus(),
                  ),

                  const SizedBox(height: 8),

                  // BEST
                  _buildRecommendationCard(
                    title: 'BEST OPTION',
                    icon: Icons.star,
                    iconColor: Colors.amber,
                    bus: _getBestBus(),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // STOP DROPDOWN
  // ============================================================

  Widget _buildStopDropdown({
    required BuildContext context,
    required String title,
    required IconData icon,
    required BusStop? value,
    required List<BusStop> stops,
    required ValueChanged<BusStop?> onChanged,
  }) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 12,
      ),
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.grey.shade300,
        ),
        borderRadius:
            BorderRadius.circular(10),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<BusStop>(
          value: value,
          isExpanded: true,
          hint: Row(
            children: [
              Icon(
                icon,
                size: 19,
              ),
              const SizedBox(width: 8),
              Text(title),
            ],
          ),
          items: stops.map(
            (stop) {
              return DropdownMenuItem<
                  BusStop>(
                value: stop,
                child: Text(
                  stop.nameEn,
                  overflow:
                      TextOverflow.ellipsis,
                ),
              );
            },
          ).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  // ============================================================
  // PLAN TRIP
  // ============================================================

  void _planTrip(
    TransitProvider provider,
  ) {
    if (_fromStop == null ||
        _toStop == null ||
        _arrivalTime == null) {
      _showMessage(
        'Please select From, To and arrival time.',
      );
      return;
    }

    if (_fromStop!.id ==
        _toStop!.id) {
      _showMessage(
        'From and To cannot be the same stop.',
      );
      return;
    }

    final matching = provider.buses
        .where(
          (bus) {
            final fromIndex =
                bus.stopIds.indexOf(
              _fromStop!.id,
            );

            final toIndex =
                bus.stopIds.indexOf(
              _toStop!.id,
            );

            // Bus must contain both stops
            // and travel From -> To.
            return fromIndex >= 0 &&
                toIndex >= 0 &&
                fromIndex < toIndex;
          },
        )
        .toList();

    setState(() {
      _matchingBuses = matching;
      _showResults = true;
    });
  }

  // ============================================================
  // FASTEST BUS
  // ============================================================

  Bus _getFastestBus() {
    final buses = [..._matchingBuses];

    buses.sort(
      (a, b) => _estimatedTravelTime(a)
          .compareTo(
        _estimatedTravelTime(b),
      ),
    );

    return buses.first;
  }

  // ============================================================
  // CHEAPEST BUS
  // ============================================================

  Bus _getCheapestBus() {
    final buses = [..._matchingBuses];

    buses.sort(
      (a, b) => a.standardFare.compareTo(
        b.standardFare,
      ),
    );

    return buses.first;
  }

  // ============================================================
  // BEST OPTION
  // ============================================================

  Bus _getBestBus() {
    Bus best = _matchingBuses.first;

    double bestScore =
        double.infinity;

    for (final bus
        in _matchingBuses) {
      final time =
          _estimatedTravelTime(bus);

      final fare =
          bus.standardFare;

      // Balanced score:
      // travel time + fare + small
      // penalty for non-live buses.
      final score =
          time +
          (fare * 0.20) +
          (bus.isLive ? 0 : 5);

      if (score < bestScore) {
        bestScore = score;
        best = bus;
      }
    }

    return best;
  }

  // ============================================================
  // ESTIMATED TRAVEL TIME
  // ============================================================

  int _estimatedTravelTime(
    Bus bus,
  ) {
    if (_fromStop == null ||
        _toStop == null) {
      return bus.etaMinutes;
    }

    final fromIndex =
        bus.stopIds.indexOf(
      _fromStop!.id,
    );

    final toIndex =
        bus.stopIds.indexOf(
      _toStop!.id,
    );

    if (fromIndex < 0 ||
        toIndex < 0 ||
        toIndex <= fromIndex) {
      return bus.etaMinutes;
    }

    final numberOfStops =
        toIndex - fromIndex;

    // Demo estimation.
    // Each stop-to-stop segment is
    // estimated as 5 minutes.
    const minutesPerStop = 5;

    final estimated =
        numberOfStops *
            minutesPerStop;

    return estimated > 0
        ? estimated
        : bus.etaMinutes;
  }

  // ============================================================
  // RECOMMENDATION CARD
  // ============================================================

  Widget _buildRecommendationCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required Bus bus,
  }) {
    final travelTime =
        _estimatedTravelTime(bus);

    return Card(
      margin: EdgeInsets.zero,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius:
            BorderRadius.circular(12),
        onTap: () {
          final provider =
              Provider.of<
                  TransitProvider>(
            context,
            listen: false,
          );

          provider.selectBus(bus);

          setState(() {
            _showSmartPlan = false;
            _showResults = false;
          });
        },
        child: Padding(
          padding:
              const EdgeInsets.all(11),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [

              // ----------------------------------------------------
              // LABEL
              // ----------------------------------------------------

              Row(
                children: [
                  Icon(
                    icon,
                    color: iconColor,
                    size: 19,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    title,
                    style:
                        const TextStyle(
                      fontWeight:
                          FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 6),

              // ----------------------------------------------------
              // BUS NAME
              // ----------------------------------------------------

              Text(
                bus.company,
                style:
                    const TextStyle(
                  fontWeight:
                      FontWeight.bold,
                  fontSize: 15,
                ),
              ),

              const SizedBox(height: 4),

              // ----------------------------------------------------
              // DETAILS
              // ----------------------------------------------------

              Wrap(
                spacing: 10,
                runSpacing: 4,
                children: [

                  Row(
                    mainAxisSize:
                        MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.route,
                        size: 14,
                      ),
                      const SizedBox(
                        width: 3,
                      ),
                      Text(
                        bus.routeTag,
                        style:
                            const TextStyle(
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),

                  Row(
                    mainAxisSize:
                        MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.timer_outlined,
                        size: 14,
                      ),
                      const SizedBox(
                        width: 3,
                      ),
                      Text(
                        '$travelTime min',
                        style:
                            const TextStyle(
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),

                  Row(
                    mainAxisSize:
                        MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.payments_outlined,
                        size: 14,
                      ),
                      const SizedBox(
                        width: 3,
                      ),
                      Text(
                        '৳${bus.standardFare.toStringAsFixed(0)}',
                        style:
                            const TextStyle(
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 5),

              // ----------------------------------------------------
              // LIVE STATUS
              // ----------------------------------------------------

              Row(
                children: [
                  Icon(
                    Icons.circle,
                    size: 8,
                    color: bus.isLive
                        ? Colors.green
                        : Colors.orange,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    bus.isLive
                        ? 'Live tracking'
                        : 'Scheduled',
                    style:
                        const TextStyle(
                      fontSize: 11,
                    ),
                  ),
                  const Spacer(),
                  const Icon(
                    Icons.arrow_forward_ios,
                    size: 12,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // NO RESULT
  // ============================================================

  Widget _buildNoResultCard() {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.orange
            .withOpacity(0.08),
        borderRadius:
            BorderRadius.circular(12),
      ),
      child: const Column(
        children: [

          Icon(
            Icons.search_off,
            color: Colors.orange,
            size: 30,
          ),

          SizedBox(height: 6),

          Text(
            'No direct bus found',
            style: TextStyle(
              fontWeight:
                  FontWeight.bold,
            ),
          ),

          SizedBox(height: 3),

          Text(
            'Try another starting point or destination.',
            textAlign:
                TextAlign.center,
            style: TextStyle(
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // TIME PICKER
  // ============================================================

  Future<void>
      _selectArrivalTime() async {
    final selected =
        await showTimePicker(
      context: context,
      initialTime:
          TimeOfDay.now(),
    );

    if (selected != null) {
      setState(() {
        _arrivalTime = selected;
        _showResults = false;
      });
    }
  }

  // ============================================================
  // SELECTED BUS CARD
  // ============================================================

  Widget _buildSelectedBusCard(
    TransitProvider provider,
    LanguageProvider langProvider,
  ) {
    final bus =
        provider.selectedBus!;

    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(16),
      ),
      child: Padding(
        padding:
            const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        child: Row(
          children: [

            Container(
              padding:
                  const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color:
                    Colors.orange.shade100,
                borderRadius:
                    BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.directions_bus,
                color: Colors.deepOrange,
              ),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                mainAxisSize:
                    MainAxisSize.min,
                children: [

                  Text(
                    langProvider.isBangla
                        ? bus.companyBn
                        : bus.company,
                    style:
                        const TextStyle(
                      fontWeight:
                          FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),

                  Text(
                    '${bus.routeTag} • ${bus.routeName}',
                    style: TextStyle(
                      color:
                          Colors.grey.shade600,
                      fontSize: 12,
                    ),
                    overflow:
                        TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            IconButton(
              icon: const Icon(
                Icons.close,
                color: Colors.redAccent,
              ),
              tooltip: 'Stop Tracking',
              onPressed: () {
                provider
                    .clearStopSelection();
              },
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // ARRIVALS BOTTOM SHEET
  // ============================================================

  void _showArrivalsBottomSheet(
    BuildContext context,
    BusStop stop,
    TransitProvider provider,
    LanguageProvider langProvider,
  ) {
    showModalBottomSheet(
      context: context,
      shape:
          const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      builder: (context) {

        final buses =
            provider
                .getBusesForSelectedStop();

        final stopName =
            langProvider.isBangla
                ? stop.nameBn
                : stop.nameEn;

        return Container(
          padding:
              const EdgeInsets.all(16),
          height: 350,
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [

              Text(
                '$stopName ${langProvider.t('Upcoming Arrivals')}',
                style:
                    const TextStyle(
                  fontSize: 20,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              const Divider(),

              Expanded(
                child: buses.isEmpty
                    ? Center(
                        child: Text(
                          langProvider.t(
                            'No buses currently scheduled.',
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount:
                            buses.length,
                        itemBuilder:
                            (context, index) {

                          final bus =
                              buses[index];

                          final companyName =
                              langProvider.isBangla
                                  ? bus.companyBn
                                  : bus.company;

                          return ListTile(
                            leading:
                                Container(
                              padding:
                                  const EdgeInsets
                                      .all(8),
                              decoration:
                                  BoxDecoration(
                                color: Colors
                                    .green
                                    .shade100,
                                borderRadius:
                                    BorderRadius
                                        .circular(
                                  8,
                                ),
                              ),
                              child: Text(
                                bus.routeTag,
                                style:
                                    TextStyle(
                                  fontWeight:
                                      FontWeight
                                          .bold,
                                  color: Colors
                                      .green
                                      .shade900,
                                ),
                              ),
                            ),

                            title: Text(
                              companyName,
                              style:
                                  const TextStyle(
                                fontWeight:
                                    FontWeight
                                        .bold,
                              ),
                            ),

                            subtitle: Text(
                              langProvider.t(
                                bus.isLive
                                    ? 'LIVE TRACKING'
                                    : 'SCHEDULED',
                              ),
                              style: TextStyle(
                                color: bus.isLive
                                    ? Colors.green
                                    : Colors.grey,
                              ),
                            ),

                            trailing: Text(
                              '${bus.etaMinutes} min',
                              style:
                                  const TextStyle(
                                fontSize: 18,
                                color:
                                    Colors.orange,
                                fontWeight:
                                    FontWeight
                                        .bold,
                              ),
                            ),

                            onTap: () {
                              provider
                                  .selectBus(
                                bus,
                              );

                              Navigator.pop(
                                context,
                              );
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(
    String message,
  ) {
    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }
}