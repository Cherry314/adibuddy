import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/trip_data_point.dart';
import '../services/trip_logger_service.dart';

/// Screen to display trip data on an OpenStreetMap
/// Shows all data points with colored markers for events
class TripMapScreen extends StatefulWidget {
  final TripLoggerService tripLogger;

  const TripMapScreen({
    super.key,
    required this.tripLogger,
  });

  @override
  State<TripMapScreen> createState() => _TripMapScreenState();
}

class _TripMapScreenState extends State<TripMapScreen> {
  final MapController _mapController = MapController();
  bool _showAllPoints = false;
  TripDataPoint? _selectedPoint;

  @override
  Widget build(BuildContext context) {
    final tripData = widget.tripLogger.tripData;
    final eventPoints = widget.tripLogger.getEventPoints();
    final displayPoints = _showAllPoints ? tripData : eventPoints;

    if (tripData.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Trip Review'),
          backgroundColor: Colors.purple[400],
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.map_outlined, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'No trip data available',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
              SizedBox(height: 8),
              Text(
                'Start tracking to record a journey',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    // Calculate center of trip
    final center = _calculateCenter(tripData);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trip Review'),
        backgroundColor: Colors.purple[400],
        actions: [
          // Toggle between showing all points or just events
          TextButton.icon(
            onPressed: () {
              setState(() {
                _showAllPoints = !_showAllPoints;
              });
            },
            icon: Icon(
              _showAllPoints ? Icons.filter_list : Icons.filter_list_off,
              color: Colors.white,
            ),
            label: Text(
              _showAllPoints ? 'Show Events Only' : 'Show All Points',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Trip summary card
          _buildSummaryCard(),
          
          // Map
          Expanded(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: center,
                initialZoom: 15,
              ),
              children: [
                // OpenStreetMap tiles
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.adibuddy',
                ),
                
                // Trip path polyline
                if (tripData.length > 1)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: tripData.map((p) => p.position).toList(),
                        color: Colors.blue.withOpacity(0.5),
                        strokeWidth: 4,
                      ),
                    ],
                  ),
                
                // Event markers
                MarkerLayer(
                  markers: displayPoints.map((point) {
                    return Marker(
                      point: point.position,
                      width: _showAllPoints && !point.hasEvent ? 20 : 40,
                      height: _showAllPoints && !point.hasEvent ? 20 : 40,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedPoint = point;
                          });
                        },
                        child: _buildMarker(point),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          
          // Selected point details
          if (_selectedPoint != null)
            _buildPointDetailsCard(_selectedPoint!),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    final summary = widget.tripLogger.getTripSummary();
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStat('Duration', '${summary['duration']} min', Icons.timer),
          _buildStat('Points', '${summary['dataPoints']}', Icons.location_on),
          _buildStat('Events', '${summary['events']}', Icons.warning),
          _buildStat('Max Speed', '${summary['maxSpeed']} mph', Icons.speed),
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value, IconData icon) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20, color: Colors.purple[400]),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildMarker(TripDataPoint point) {
    // Normal driving - small green dot
    if (!point.hasEvent && _showAllPoints) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.green,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 1),
        ),
      );
    }

    // Event markers - larger colored circles with icons
    Color color;
    IconData icon;
    
    switch (point.eventColor) {
      case 'red':
        color = Colors.red;
        icon = Icons.warning;
        break;
      case 'orange':
        color = Colors.orange;
        icon = Icons.arrow_upward;
        break;
      case 'purple':
        color = Colors.purple;
        icon = Icons.rotate_right;
        break;
      case 'blue':
        color = Colors.blue;
        icon = Icons.speed;
        break;
      default:
        color = Colors.green;
        icon = Icons.check_circle;
    }

    return Container(
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.4),
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Icon(
        icon,
        color: Colors.white,
        size: 20,
      ),
    );
  }

  Widget _buildPointDetailsCard(TripDataPoint point) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                point.eventDescription,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: point.hasEvent ? Colors.red[700] : Colors.green[700],
                ),
              ),
              IconButton(
                onPressed: () {
                  setState(() {
                    _selectedPoint = null;
                  });
                },
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildDetail('Speed', '${point.speedMph.toStringAsFixed(1)} mph'),
              _buildDetail('Lateral G', point.gForceLateral.toStringAsFixed(2)),
              _buildDetail('Longitudinal G', point.gForceLongitudinal.toStringAsFixed(2)),
            ],
          ),
          if (point.speedLimitMph != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Speed Limit: ${point.speedLimitMph} mph',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDetail(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  LatLng _calculateCenter(List<TripDataPoint> points) {
    if (points.isEmpty) return const LatLng(51.5074, -0.1278); // Default: London
    
    double latSum = 0;
    double lngSum = 0;
    
    for (final point in points) {
      latSum += point.position.latitude;
      lngSum += point.position.longitude;
    }
    
    return LatLng(latSum / points.length, lngSum / points.length);
  }
}
