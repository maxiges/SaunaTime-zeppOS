import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart' as intl;

import '../../../../core/localization/app_localizations.dart';
import '../../domain/models/measurement_sample.dart';
import '../../domain/models/sauna_phase.dart';

/// Telemetry chart displaying heart rate or temperature data.
/// Has an interactive full-screen view with precise inspection.
class TelemetryChart extends StatelessWidget {
  final String title;
  final String unit;
  final List<MeasurementSample> samples;
  final Color lineColor;
  final IconData icon;

  /// Optional, localized phase names (e.g. "Heating", "Cooling").
  final Map<SaunaPhase, String>? phaseNames;

  const TelemetryChart({
    super.key,
    required this.title,
    required this.unit,
    required this.samples,
    required this.lineColor,
    required this.icon,
    this.phaseNames,
  });

  @override
  Widget build(BuildContext context) {
    if (samples.isEmpty) return const SizedBox.shrink();

    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final values = samples.map((s) => s.value).toList();
    final minValue = values.reduce(math.min);
    final maxValue = values.reduce(math.max);
    final avgValue = values.reduce((a, b) => a + b) / values.length;

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: lineColor, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  onPressed: () => _openFullScreen(context),
                  tooltip: l['chart_zoom_hint'],
                  icon: Icon(Icons.zoom_in_rounded, size: 22, color: theme.colorScheme.primary),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildCompactStat(l['chart_min'], '${minValue.toStringAsFixed(0)} $unit', theme),
                _buildCompactStat(l['chart_avg'], '${avgValue.toStringAsFixed(0)} $unit', theme),
                _buildCompactStat(l['chart_max'], '${maxValue.toStringAsFixed(0)} $unit', theme),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 130,
              width: double.infinity,
              child: _ChartInteractive(
                samples: samples,
                lineColor: lineColor,
                gridColor: theme.dividerColor.withValues(alpha: 0.2),
                unit: unit,
                phaseNames: phaseNames,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openFullScreen(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => _FullScreenChartPage(
          title: title,
          unit: unit,
          samples: samples,
          lineColor: lineColor,
          icon: icon,
          phaseNames: phaseNames,
        ),
      ),
    );
  }

  Widget _buildCompactStat(String label, String value, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      ],
    );
  }
}

class _FullScreenChartPage extends StatefulWidget {
  final String title;
  final String unit;
  final List<MeasurementSample> samples;
  final Color lineColor;
  final IconData icon;
  final Map<SaunaPhase, String>? phaseNames;

  const _FullScreenChartPage({
    required this.title,
    required this.unit,
    required this.samples,
    required this.lineColor,
    required this.icon,
    this.phaseNames,
  });

  @override
  State<_FullScreenChartPage> createState() => _FullScreenChartPageState();
}

class _FullScreenChartPageState extends State<_FullScreenChartPage> {
  double _zoomLevel = 1.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);
    final mediaQuery = MediaQuery.of(context);
    final isLandscape = mediaQuery.orientation == Orientation.landscape;
    final screenWidth = mediaQuery.size.width;

    final values = widget.samples.map((s) => s.value).toList();
    final minValue = values.reduce(math.min);
    final maxValue = values.reduce(math.max);
    final avgValue = values.reduce((a, b) => a + b) / values.length;

    final presentPhases = <SaunaPhase>{};
    for (final sample in widget.samples) {
      if (sample.phase != null) presentPhases.add(sample.phase!);
    }

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Text(widget.title),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.zoom_in, size: 18),
                const SizedBox(width: 4),
                DropdownButton<double>(
                  value: _zoomLevel,
                  underline: const SizedBox(),
                  icon: const Icon(Icons.arrow_drop_down, size: 18),
                  onChanged: (val) {
                    if (val != null) setState(() => _zoomLevel = val);
                  },
                  items: const [
                    DropdownMenuItem(value: 1.0, child: Text('1x')),
                    DropdownMenuItem(value: 2.0, child: Text('2x')),
                    DropdownMenuItem(value: 4.0, child: Text('4x')),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Statistics panel at the top
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                vertical: isLandscape ? 8 : 24,
                horizontal: 16,
              ),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerLow,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStatBox(l['chart_min'], '${minValue.toStringAsFixed(1)} ${widget.unit}', theme, isLandscape),
                      _buildStatBox(l['chart_avg'], '${avgValue.toStringAsFixed(1)} ${widget.unit}', theme, isLandscape),
                      _buildStatBox(l['chart_max'], '${maxValue.toStringAsFixed(1)} ${widget.unit}', theme, isLandscape),
                    ],
                  ),
                  if (presentPhases.isNotEmpty) ...[
                    SizedBox(height: isLandscape ? 8 : 20),
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: presentPhases.map((phase) => _PhaseLegendChip(
                        color: phase.color,
                        label: widget.phaseNames?[phase] ?? phase.name,
                      )).toList(),
                    ),
                  ],
                ],
              ),
            ),

            // Interaktywny obszar wykresu
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: SizedBox(
                  width: math.max(screenWidth, screenWidth * _zoomLevel),
                  height: double.infinity,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      24,
                      isLandscape ? 20 : 60,
                      48,
                      isLandscape ? 30 : 80,
                    ),
                    child: _ChartInteractive(
                      samples: widget.samples,
                      lineColor: widget.lineColor,
                      gridColor: theme.dividerColor.withValues(alpha: 0.15),
                      unit: widget.unit,
                      phaseNames: widget.phaseNames,
                      fullScreen: true,
                    ),
                  ),
                ),
              ),
            ),
            
            // Touch hint
            Padding(
              padding: EdgeInsets.all(isLandscape ? 8.0 : 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.touch_app_outlined, size: 16, color: theme.colorScheme.primary.withValues(alpha: 0.6)),
                  const SizedBox(width: 8),
                  Text(l['chart_tap_hint'], style: theme.textTheme.bodySmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatBox(String label, String value, ThemeData theme, bool isLandscape) {
    return Column(
      children: [
        Text(label, style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          letterSpacing: 1.1,
          fontSize: isLandscape ? 10 : null,
        )),
        SizedBox(height: isLandscape ? 2 : 4),
        Text(value, style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: isLandscape ? 16 : 18,
        )),
      ],
    );
  }
}

class _ChartInteractive extends StatefulWidget {
  final List<MeasurementSample> samples;
  final Color lineColor;
  final Color gridColor;
  final String unit;
  final Map<SaunaPhase, String>? phaseNames;
  final bool fullScreen;

  const _ChartInteractive({
    required this.samples,
    required this.lineColor,
    required this.gridColor,
    required this.unit,
    this.phaseNames,
    this.fullScreen = false,
  });

  @override
  State<_ChartInteractive> createState() => _ChartInteractiveState();
}

class _ChartInteractiveState extends State<_ChartInteractive> {
  int? _selectedIndex;

  List<MeasurementSample> get _sorted =>
      [...widget.samples]..sort((a, b) => a.timestamp.compareTo(b.timestamp));

  void _onInteraction(Offset localPosition, double width) {
    final sorted = _sorted;
    if (sorted.isEmpty) return;

    final start = sorted.first.timestamp.millisecondsSinceEpoch;
    final end = sorted.last.timestamp.millisecondsSinceEpoch;
    final total = math.max(1, end - start);
    final targetTime = start + (localPosition.dx / width) * total;

    int bestIndex = 0;
    double minDiff = double.infinity;
    for (int i = 0; i < sorted.length; i++) {
      final diff = (sorted[i].timestamp.millisecondsSinceEpoch - targetTime).abs().toDouble();
      if (diff < minDiff) {
        minDiff = diff;
        bestIndex = i;
      }
    }

    if (_selectedIndex != bestIndex) {
      setState(() => _selectedIndex = bestIndex);
      HapticFeedback.selectionClick();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sorted = _sorted;
    final selected = _selectedIndex != null ? sorted[_selectedIndex!] : null;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (d) => _onInteraction(d.localPosition, width),
          onHorizontalDragUpdate: (d) => _onInteraction(d.localPosition, width),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _ChartPainter(
                    samples: widget.samples,
                    lineColor: widget.lineColor,
                    gridColor: widget.gridColor,
                    textColor: theme.colorScheme.onSurfaceVariant,
                    selectedIndex: _selectedIndex,
                    showLabels: widget.fullScreen,
                  ),
                ),
              ),
              if (selected != null)
                _buildDynamicTooltip(theme, sorted, _selectedIndex!, width, height),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDynamicTooltip(ThemeData theme, List<MeasurementSample> sorted, int index, double width, double height) {
    final sample = sorted[index];
    final timeStr = intl.DateFormat('HH:mm:ss').format(sample.timestamp.toLocal());
    final valueStr = '${sample.value.toStringAsFixed(1)} ${widget.unit}';
    final phaseColor = sample.phase?.color ?? widget.lineColor;

    final start = sorted.first.timestamp.millisecondsSinceEpoch;
    final end = sorted.last.timestamp.millisecondsSinceEpoch;
    final dx = ((sample.timestamp.millisecondsSinceEpoch - start) / math.max(1, end - start)) * width;

    // Convert the point's Y for tooltip positioning
    final values = sorted.map((s) => s.value).toList();
    final minV = values.reduce(math.min);
    final maxV = values.reduce(math.max);
    final valRange = math.max(0.1, maxV - minV);
    final displayMin = minV - (valRange * 0.1);
    final displayMax = maxV + (valRange * 0.1);
    final displayRange = displayMax - displayMin;
    final dy = height - ((sample.value - displayMin) / displayRange * height);

    const tw = 170.0;
    const th = 70.0;
    final double left = (dx - tw / 2).clamp(4.0, math.max(4.0, width - tw - 4.0)).toDouble();
    final double top = (dy - th - 24).clamp(0.0, height).toDouble();

    return Positioned(
      left: left,
      top: top,
      width: tw,
      child: IgnorePointer(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: theme.colorScheme.inverseSurface.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [BoxShadow(color: Colors.black45, blurRadius: 12, offset: const Offset(0, 6))],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(timeStr, style: TextStyle(fontSize: 10, color: theme.colorScheme.onInverseSurface.withValues(alpha: 0.6), fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Row(
                children: [
                  Container(width: 8, height: 8, decoration: BoxDecoration(color: phaseColor, shape: BoxShape.circle)),
                  const SizedBox(width: 8),
                  Expanded(child: Text(valueStr, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: theme.colorScheme.onInverseSurface))),
                ],
              ),
              if (sample.phase != null)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    widget.phaseNames?[sample.phase!] ?? sample.phase!.name,
                    style: TextStyle(fontSize: 10, color: phaseColor.withValues(alpha: 0.9), fontWeight: FontWeight.w700),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChartPainter extends CustomPainter {
  final List<MeasurementSample> samples;
  final Color lineColor;
  final Color gridColor;
  final Color textColor;
  final int? selectedIndex;
  final bool showLabels;

  _ChartPainter({
    required this.samples,
    required this.lineColor,
    required this.gridColor,
    required this.textColor,
    this.selectedIndex,
    this.showLabels = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (samples.length < 2) return;

    final sorted = [...samples]..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    final values = sorted.map((s) => s.value).toList();
    var minVal = values.reduce(math.min);
    var maxVal = values.reduce(math.max);

    final valRange = math.max(0.1, maxVal - minVal);
    final displayMin = minVal - (valRange * 0.1);
    final displayMax = maxVal + (valRange * 0.1);
    final displayRange = displayMax - displayMin;

    // Grid
    final gridPaint = Paint()..color = gridColor..strokeWidth = 1.2;
    for (var i = 0; i <= 2; i++) {
      final y = size.height * (i / 2);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
      if (showLabels) {
        final val = displayMax - (i / 2) * displayRange;
        _drawText(canvas, val.toStringAsFixed(0), Offset(size.width + 10, y - 8), textColor, true);
      }
    }

    final startTime = sorted.first.timestamp.millisecondsSinceEpoch;
    final totalDuration = math.max(1, sorted.last.timestamp.millisecondsSinceEpoch - startTime);

    final points = <Offset>[];
    for (final s in sorted) {
      final x = ((s.timestamp.millisecondsSinceEpoch - startTime) / totalDuration) * size.width;
      final y = size.height - ((s.value - displayMin) / displayRange * size.height);
      points.add(Offset(x, y));
    }

    // Phase gradients
    for (var i = 0; i < points.length - 1; i++) {
      final color = sorted[i].phase?.color ?? lineColor;
      final path = Path()
        ..moveTo(points[i].dx, size.height)
        ..lineTo(points[i].dx, points[i].dy)
        ..lineTo(points[i+1].dx, points[i+1].dy)
        ..lineTo(points[i+1].dx, size.height)
        ..close();

      final grad = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [color.withValues(alpha: 0.25), color.withValues(alpha: 0.0)],
      ).createShader(Rect.fromLTWH(points[i].dx, 0, points[i+1].dx - points[i].dx, size.height));

      canvas.drawPath(path, Paint()..shader = grad);
    }

    // Main line
    for (var i = 0; i < points.length - 1; i++) {
      final color = sorted[i].phase?.color ?? lineColor;
      canvas.drawLine(points[i], points[i + 1], Paint()
        ..color = color
        ..strokeWidth = showLabels ? 4.0 : 3.0
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke);
    }

    // Inspection indicator
    if (selectedIndex != null && selectedIndex! < points.length) {
      final p = points[selectedIndex!];
      final color = sorted[selectedIndex!].phase?.color ?? lineColor;

      final guidePaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withValues(alpha: 0.5), color.withValues(alpha: 0.1)],
        ).createShader(Rect.fromLTWH(p.dx - 1, 0, 2, size.height))
        ..strokeWidth = 2;
      canvas.drawLine(Offset(p.dx, 0), Offset(p.dx, size.height), guidePaint);

      canvas.drawCircle(p, 7, Paint()..color = color);
      canvas.drawCircle(p, 7, Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 2.5);
    }

    // Etykiety czasu
    if (showLabels) {
      final startT = intl.DateFormat('HH:mm').format(sorted.first.timestamp.toLocal());
      final endT = intl.DateFormat('HH:mm').format(sorted.last.timestamp.toLocal());
      _drawText(canvas, startT, Offset(0, size.height + 14), textColor, false);
      _drawText(canvas, endT, Offset(size.width - 35, size.height + 14), textColor, false);
    }
  }

  void _drawText(Canvas canvas, String text, Offset offset, Color color, bool bold) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: bold ? FontWeight.bold : FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    tp.layout();
    tp.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant _ChartPainter old) => 
      old.selectedIndex != selectedIndex || old.samples != samples || old.showLabels != showLabels;
}

class _PhaseLegendChip extends StatelessWidget {
  final Color color;
  final String label;

  const _PhaseLegendChip({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }
}
