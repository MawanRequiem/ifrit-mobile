import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:agniraksha_mobile/features/rooms/providers/rooms_provider.dart';
import 'package:agniraksha_mobile/features/rooms/domain/room_model.dart';
import 'package:agniraksha_mobile/features/alerts/providers/alerts_provider.dart';
import 'package:agniraksha_mobile/features/alerts/domain/alert_model.dart';
import 'package:agniraksha_mobile/features/alerts/presentation/alert_detail_sheet.dart';
import 'package:agniraksha_mobile/core/theme/app_colors.dart';
import 'package:agniraksha_mobile/core/theme/app_typography.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';

class RoomDetailScreen extends ConsumerStatefulWidget {
  final String roomId;
  const RoomDetailScreen({super.key, required this.roomId});

  @override
  ConsumerState<RoomDetailScreen> createState() => _RoomDetailScreenState();
}

class _RoomDetailScreenState extends ConsumerState<RoomDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final roomAsync = ref.watch(roomDetailProvider(widget.roomId));
    final sensorsAsync = ref.watch(roomSensorsProvider(widget.roomId));

    return Scaffold(
      appBar: AppBar(
        title: roomAsync.whenOrNull(data: (r) => Text(r.name)) ??
            const Text('Room Detail'),
      ),
      body: RefreshIndicator(
        color: AppColors.brand,
        backgroundColor: AppColors.surface1,
        onRefresh: () async {
          ref.invalidate(roomDetailProvider(widget.roomId));
          ref.invalidate(roomSensorsProvider(widget.roomId));
        },
        child: roomAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (room) {
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                // ── Room Status Header ──
                _RoomHeader(room: room),
                const SizedBox(height: 20),

                // ── Active Alerts for this Room ──
                _ActiveAlertsSection(roomId: widget.roomId),

                // ── Quick Actions ──
                _QuickActionsSection(roomId: widget.roomId, roomName: room.name),

                // ── Device Status Chips ──
                if (room.devices.isNotEmpty) ...[
                  Text(
                    'NODES',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.textMuted,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: room.devices.map((d) => _DeviceChip(device: d)).toList(),
                  ),
                  const SizedBox(height: 24),
                ],

                // ── Sensor Gauges ──
                Text(
                  'SENSORS',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.textMuted,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 10),
                sensorsAsync.when(
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  error: (e, _) => Text('Error loading sensors: $e'),
                  data: (sensors) {
                    if (sensors.isEmpty) {
                      return Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: AppColors.surface1,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Center(
                          child: Text(
                            'No sensors registered yet',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textMuted,
                            ),
                          ),
                        ),
                      );
                    }
                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        childAspectRatio: 1.4,
                      ),
                      itemCount: sensors.length,
                      itemBuilder: (context, i) => _SensorTile(
                        sensor: sensors[i],
                        onTap: () => _showSensorDialog(context, sensors[i]),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 28),
                sensorsAsync.when(
                  loading: () => const SizedBox.shrink(),
                  error: (_, stackTrace) => const SizedBox.shrink(),
                  data: (sensors) {
                    if (sensors.isEmpty) return const SizedBox.shrink();
                    return SensorHistoryChart(
                      roomId: widget.roomId,
                      sensors: sensors,
                    );
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _showSensorDialog(BuildContext context, SensorModel sensor) {
    final typeLabel = _sensorDisplayLabel(sensor.sensorType);
    final unit = _sensorDisplayUnit(sensor.sensorType);
    final value = sensor.currentValue;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _sensorColor(sensor.sensorType),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              typeLabel,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _infoRow('Type', sensor.sensorType.toUpperCase()),
            _infoRow('Value', value != null ? '${value.toStringAsFixed(2)} $unit' : 'No data'),
            _infoRow('Status', sensor.status.toUpperCase()),
            _infoRow('Device', sensor.deviceId.substring(0, 8)),
            if (sensor.lastUpdate != null) _infoRow('Updated', _formatTime(sensor.lastUpdate!)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('CLOSE', style: TextStyle(color: AppColors.textSecondary)),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
          Text(
            value,
            style: AppTypography.monoSmall.copyWith(color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }

  String _sensorDisplayLabel(String type) {
    switch (type.toUpperCase()) {
      case 'MQ2':        return 'MQ-2 (Smoke/LPG)';
      case 'MQ4':        return 'MQ-4 (Methane)';
      case 'MQ6':        return 'MQ-6 (LPG)';
      case 'MQ9':        return 'MQ-9 (CO)';
      case 'SHTC3_TEMP': return 'Temperature';
      case 'SHTC3_HUM':  return 'Humidity';
      case 'FLAME':      return 'Flame Sensor';
      default:           return type;
    }
  }

  String _sensorDisplayUnit(String type) {
    switch (type.toUpperCase()) {
      case 'SHTC3_TEMP': return '°C';
      case 'SHTC3_HUM':  return '%';
      case 'FLAME':      return '';
      default:           return 'ppm';
    }
  }

  Color _sensorColor(String type) {
    switch (type.toUpperCase()) {
      case 'MQ2':        return AppColors.sensorMQ2;
      case 'MQ4':        return AppColors.sensorMQ4;
      case 'MQ6':        return AppColors.sensorMQ6;
      case 'MQ9':        return AppColors.sensorMQ9;
      case 'SHTC3_TEMP': return AppColors.sensorTemp;
      case 'SHTC3_HUM':  return AppColors.sensorHum;
      case 'FLAME':      return AppColors.sensorFlam;
      default:           return AppColors.textSecondary;
    }
  }

  String _formatTime(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      return '${diff.inHours}h ago';
    } catch (_) {
      return iso;
    }
  }
}


// ── Room Header ─────────────────────────────────────────────
class _RoomHeader extends StatelessWidget {
  final RoomModel room;
  const _RoomHeader({required this.room});

  Color get _statusColor {
    switch (room.status) {
      case 'safe':     return AppColors.safe;
      case 'low':      return AppColors.info;
      case 'medium':   return AppColors.warning;
      case 'high':     return AppColors.critical;
      case 'critical': return AppColors.critical;
      default:         return AppColors.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _statusColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _statusColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _statusColor,
              boxShadow: [
                BoxShadow(
                  color: _statusColor.withValues(alpha: 0.5),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  room.name,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                if (room.description != null && room.description!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      room.description!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: _statusColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              room.status.toUpperCase(),
              style: AppTypography.monoSmall.copyWith(
                color: _statusColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Device Chip ─────────────────────────────────────────────
class _DeviceChip extends StatelessWidget {
  final DeviceModel device;
  const _DeviceChip({required this.device});

  Color get _statusColor {
    switch (device.status) {
      case 'online':      return AppColors.safe;
      case 'burn_in':     return AppColors.warning;
      case 'warming_up':  return AppColors.info;
      case 'calibrating': return AppColors.info;
      default:            return AppColors.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _statusColor,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            device.name ?? 'Node',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            device.status.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: _statusColor,
              fontSize: 8,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Sensor Tile ─────────────────────────────────────────────
class _SensorTile extends StatelessWidget {
  final SensorModel sensor;
  final VoidCallback? onTap;
  const _SensorTile({required this.sensor, this.onTap});

  Color get _typeColor {
    switch (sensor.sensorType.toUpperCase()) {
      case 'MQ2':        return AppColors.sensorMQ2;
      case 'MQ4':        return AppColors.sensorMQ4;
      case 'MQ6':        return AppColors.sensorMQ6;
      case 'MQ9':        return AppColors.sensorMQ9;
      case 'SHTC3_TEMP': return AppColors.sensorTemp;
      case 'SHTC3_HUM':  return AppColors.sensorHum;
      case 'FLAME':      return AppColors.sensorFlam;
      default:           return AppColors.textSecondary;
    }
  }

  String get _displayLabel {
    switch (sensor.sensorType.toUpperCase()) {
      case 'MQ2':        return 'MQ-2';
      case 'MQ4':        return 'MQ-4';
      case 'MQ6':        return 'MQ-6';
      case 'MQ9':        return 'MQ-9';
      case 'SHTC3_TEMP': return 'Temp';
      case 'SHTC3_HUM':  return 'Humidity';
      case 'FLAME':      return 'Flame';
      default:           return sensor.sensorType;
    }
  }

  String get _displayUnit {
    switch (sensor.sensorType.toUpperCase()) {
      case 'SHTC3_TEMP': return '°C';
      case 'SHTC3_HUM':  return '%';
      case 'FLAME':      return '';
      default:           return 'ppm';
    }
  }

  @override
  Widget build(BuildContext context) {
    final value = sensor.currentValue;
    final displayValue = value != null ? value.toStringAsFixed(1) : '--';

    return GestureDetector(
      onTap: onTap,
      child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface1,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _typeColor,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _displayLabel,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                displayValue,
                style: AppTypography.monoLarge.copyWith(color: _typeColor),
              ),
              if (_displayUnit.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 3),
                  child: Text(
                    _displayUnit,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.textMuted,
                    ),
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

// ── Sensor History Chart Widget ─────────────────────────────
class SensorHistoryChart extends ConsumerStatefulWidget {
  final String roomId;
  final List<SensorModel> sensors;

  const SensorHistoryChart({
    super.key,
    required this.roomId,
    required this.sensors,
  });

  @override
  ConsumerState<SensorHistoryChart> createState() => _SensorHistoryChartState();
}

class _SensorHistoryChartState extends ConsumerState<SensorHistoryChart> {
  String _selectedRange = '30m'; // '30m', '1h', '6h', '24h'
  String? _selectedSensorType;

  @override
  void initState() {
    super.initState();
    if (widget.sensors.isNotEmpty) {
      _selectedSensorType = widget.sensors.first.sensorType;
    }
  }

  Color _getSensorColor(String type) {
    switch (type.toUpperCase()) {
      case 'MQ2':        return AppColors.sensorMQ2;
      case 'MQ4':        return AppColors.sensorMQ4;
      case 'MQ6':        return AppColors.sensorMQ6;
      case 'MQ9':        return AppColors.sensorMQ9;
      case 'SHTC3_TEMP': return AppColors.sensorTemp;
      case 'SHTC3_HUMID':
      case 'SHTC3_HUM':  return AppColors.sensorHum;
      case 'FLAME':      return AppColors.sensorFlam;
      default:           return AppColors.brand;
    }
  }

  String _getSensorDisplayLabel(String type) {
    switch (type.toUpperCase()) {
      case 'MQ2':        return 'MQ-2';
      case 'MQ4':        return 'MQ-4';
      case 'MQ6':        return 'MQ-6';
      case 'MQ9':        return 'MQ-9';
      case 'SHTC3_TEMP': return 'Temp';
      case 'SHTC3_HUMID':
      case 'SHTC3_HUM':  return 'Humidity';
      case 'FLAME':      return 'Flame';
      default:           return type;
    }
  }

  String _getSensorUnit(String type) {
    switch (type.toUpperCase()) {
      case 'SHTC3_TEMP': return '°C';
      case 'SHTC3_HUMID':
      case 'SHTC3_HUM':  return '%';
      case 'FLAME':      return '';
      default:           return 'ppm';
    }
  }

  double _calculateInterval(double? minX, double? maxX) {
    if (minX == null || maxX == null) return 60000;
    final diff = maxX - minX;
    if (diff <= 0) return 60000;
    return diff / 4;
  }

  @override
  Widget build(BuildContext context) {
    if (_selectedSensorType == null && widget.sensors.isNotEmpty) {
      _selectedSensorType = widget.sensors.first.sensorType;
    }

    if (_selectedSensorType == null) {
      return const SizedBox.shrink();
    }

    final historyAsync = ref.watch(sensorHistoryProvider((
      roomId: widget.roomId,
      range: _selectedRange,
    )));

    final selectedColor = _getSensorColor(_selectedSensorType!);
    final unit = _getSensorUnit(_selectedSensorType!);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title and Range Selector
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'TELEMETRY TRENDS',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.textMuted,
                letterSpacing: 1.2,
              ),
            ),
            // Range pills
            Row(
              children: ['30m', '1h', '6h', '24h'].map((range) {
                final isSelected = range == _selectedRange;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedRange = range;
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.only(left: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.brand : AppColors.surface2,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isSelected ? Colors.transparent : AppColors.border,
                      ),
                    ),
                    child: Text(
                      range.toUpperCase(),
                      style: AppTypography.monoSmall.copyWith(
                        color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        fontSize: 9,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Sensor Type Selection Pills
        SizedBox(
          height: 38,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: widget.sensors.length,
            itemBuilder: (context, index) {
              final type = widget.sensors[index].sensorType;
              final isSelected = type == _selectedSensorType;
              final color = _getSensorColor(type);
              final label = _getSensorDisplayLabel(type);

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedSensorType = type;
                  });
                },
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? color.withValues(alpha: 0.1) : AppColors.surface1,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? color : AppColors.border,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: color,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        label,
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),

        // Chart Container
        Container(
          height: 220,
          padding: const EdgeInsets.fromLTRB(10, 16, 20, 10),
          decoration: BoxDecoration(
            color: AppColors.surface1,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: historyAsync.when(
            loading: () => const Center(
              child: CircularProgressIndicator(color: AppColors.brand),
            ),
            error: (err, _) => Center(
              child: Text(
                'Failed to load history: $err',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.critical,
                ),
              ),
            ),
            data: (historyData) {
              final spots = <FlSpot>[];
              double? minX;
              double? maxX;
              double? minY;
              double? maxY;

              for (final entry in historyData) {
                final timeStr = entry['time'] as String?;
                if (timeStr == null) continue;
                final val = entry[_selectedSensorType];
                if (val == null) continue;
                final y = (val is num) ? val.toDouble() : double.tryParse(val.toString());
                if (y == null) continue;

                final dt = DateTime.parse(timeStr).toLocal();
                final x = dt.millisecondsSinceEpoch.toDouble();

                spots.add(FlSpot(x, y));

                if (minX == null || x < minX) minX = x;
                if (maxX == null || x > maxX) maxX = x;
                if (minY == null || y < minY) minY = y;
                if (maxY == null || y > maxY) maxY = y;
              }

              if (spots.length < 2) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.analytics_outlined,
                        color: AppColors.textMuted,
                        size: 32,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'No trends recorded in this period.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                );
              }

              // Apply small padding to Y axis limits to look perfect
              final yRange = (maxY ?? 0) - (minY ?? 0);
              final paddedMinY = yRange == 0 ? (minY ?? 0) * 0.9 : (minY ?? 0) - yRange * 0.1;
              final paddedMaxY = yRange == 0 ? (maxY ?? 10) * 1.1 : (maxY ?? 0) + yRange * 0.1;

              return LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (val) => FlLine(
                      color: AppColors.border.withValues(alpha: 0.4),
                      strokeWidth: 1,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 42,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toStringAsFixed(0),
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: AppColors.textMuted,
                              fontSize: 9,
                            ),
                            textAlign: TextAlign.right,
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 24,
                        interval: _calculateInterval(minX, maxX),
                        getTitlesWidget: (value, meta) {
                          final dt = DateTime.fromMillisecondsSinceEpoch(value.toInt());
                          return Padding(
                            padding: const EdgeInsets.only(top: 6.0),
                            child: Text(
                              DateFormat('HH:mm').format(dt),
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: AppColors.textMuted,
                                fontSize: 9,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  minX: minX,
                  maxX: maxX,
                  minY: paddedMinY < 0 ? 0 : paddedMinY,
                  maxY: paddedMaxY,
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipColor: (touchedSpot) => AppColors.surface2,
                      tooltipBorder: const BorderSide(color: AppColors.border),
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((spot) {
                          final dt = DateTime.fromMillisecondsSinceEpoch(spot.x.toInt());
                          final timeStr = DateFormat('HH:mm:ss').format(dt);
                          return LineTooltipItem(
                            '${spot.y.toStringAsFixed(1)} $unit\n$timeStr',
                            Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.bold,
                            ) ?? const TextStyle(),
                          );
                        }).toList();
                      },
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: selectedColor,
                      barWidth: 2,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            selectedColor.withValues(alpha: 0.25),
                            selectedColor.withValues(alpha: 0.00),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}


// ── Active Alerts Section ──────────────────────────────────
class _ActiveAlertsSection extends ConsumerWidget {
  final String roomId;
  const _ActiveAlertsSection({required this.roomId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alertsState = ref.watch(alertsProvider);

    // Filter alerts for this room
    final roomAlerts = alertsState.items
        .where((a) => a.roomId == roomId && !a.isAcknowledged)
        .toList();

    if (roomAlerts.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.critical,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'ACTIVE ALERTS (${roomAlerts.length})',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.critical,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ...roomAlerts.map((alert) => _RoomAlertTile(
          alert: alert,
          onAcknowledge: () {
            ref.read(alertsProvider.notifier).acknowledge(alert.id);
          },
          onTap: () {
            AlertDetailSheet.show(context, alert: alert);
          },
        )),
        const SizedBox(height: 20),
      ],
    );
  }
}

class _RoomAlertTile extends StatelessWidget {
  final AlertModel alert;
  final VoidCallback onAcknowledge;
  final VoidCallback onTap;

  const _RoomAlertTile({
    required this.alert,
    required this.onAcknowledge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.critical.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.critical.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, size: 20, color: AppColors.critical),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    alert.message ?? alert.alertType ?? 'Alert',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    (alert.severity ?? 'warning').toUpperCase(),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.critical,
                      fontWeight: FontWeight.w700,
                      fontSize: 9,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              height: 30,
              child: TextButton(
                onPressed: onAcknowledge,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  backgroundColor: AppColors.safe.withValues(alpha: 0.1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                child: Text(
                  'ACK',
                  style: TextStyle(
                    color: AppColors.safe,
                    fontWeight: FontWeight.w700,
                    fontSize: 10,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Quick Actions Section ──────────────────────────────────
class _QuickActionsSection extends StatelessWidget {
  final String roomId;
  final String roomName;

  const _QuickActionsSection({
    required this.roomId,
    required this.roomName,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'QUICK ACTIONS',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: AppColors.textMuted,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _ActionButton(
                icon: Icons.notifications_active_outlined,
                label: 'View Alerts',
                color: AppColors.warning,
                onTap: () => context.push('/alerts'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _ActionButton(
                icon: Icons.history_rounded,
                label: 'History',
                color: AppColors.info,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Sensor history is shown in the chart below'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 22, color: color),
            const SizedBox(height: 6),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
