import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../core/constants/app_colors.dart';

/// 앱 고유 테마(보라색 포인트)를 적용한 기간형 다중 날짜 선택 다이얼로그.
/// ⚠️ 클래스명 안내:
/// Flutter 내부적으로 showDateRangePicker() 가 사용하는 프라이빗 다이얼로그와
/// 이름이 겹혀 Hot Reload 시 충돌이 발생했던 이력이 있어,
/// 반드시 `CustomDateRangePickerDialog` 라는 이름을 유지한다.
class CustomDateRangePickerDialog extends StatefulWidget {
  final String benefitTitle;
  final DateTime? initialStart;
  final DateTime? initialEnd;

  const CustomDateRangePickerDialog({
    super.key,
    required this.benefitTitle,
    this.initialStart,
    this.initialEnd,
  });

  @override
  State<CustomDateRangePickerDialog> createState() =>
      _CustomDateRangePickerDialogState();
}

class _CustomDateRangePickerDialogState
    extends State<CustomDateRangePickerDialog> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _rangeStart;
  DateTime? _rangeEnd;

  @override
  void initState() {
    super.initState();
    _rangeStart = widget.initialStart;
    _rangeEnd = widget.initialEnd;
    if (_rangeStart != null) {
      _focusedDay = _rangeStart!;
    }
  }

  void _onRangeSelected(DateTime? start, DateTime? end, DateTime focusedDay) {
    setState(() {
      _rangeStart = start;
      _rangeEnd = end;
      _focusedDay = focusedDay;
    });
  }

  bool get _canConfirm => _rangeStart != null;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.benefitTitle,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              '일정으로 등록할 기간을 선택하세요 (시작일 ~ 종료일)',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            TableCalendar(
              locale: 'ko_KR',
              firstDay: DateTime.now().subtract(const Duration(days: 365)),
              lastDay: DateTime.now().add(const Duration(days: 365 * 2)),
              focusedDay: _focusedDay,
              rangeStartDay: _rangeStart,
              rangeEndDay: _rangeEnd,
              rangeSelectionMode: RangeSelectionMode.toggledOn,
              headerStyle: const HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
              ),
              calendarStyle: CalendarStyle(
                rangeHighlightColor: AppColors.accentPurple.withValues(alpha: 0.15),
                withinRangeTextStyle: TextStyle(color: theme.colorScheme.onSurface),
                rangeStartDecoration: const BoxDecoration(
                  color: AppColors.accentPurple,
                  shape: BoxShape.circle,
                ),
                rangeEndDecoration: const BoxDecoration(
                  color: AppColors.accentPurple,
                  shape: BoxShape.circle,
                ),
                todayDecoration: BoxDecoration(
                  color: AppColors.accentPurple.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
              ),
              onRangeSelected: _onRangeSelected,
              onDaySelected: (selectedDay, focusedDay) {
                // 단일 날짜 탭 시 시작일=종료일로 취급 (하루짜리 일정도 지원)
                _onRangeSelected(selectedDay, selectedDay, focusedDay);
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('취소'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentPurple,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: _canConfirm
                        ? () {
                            final start = _rangeStart!;
                            final end = _rangeEnd ?? _rangeStart!;
                            Navigator.of(context).pop(
                              DateTimeRange(start: start, end: end),
                            );
                          }
                        : null,
                    child: const Text('등록'),
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