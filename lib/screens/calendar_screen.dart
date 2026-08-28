import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/benefit.dart';
import '../../data/storage_service.dart';
import '../../core/constants/app_colors.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final StorageService _storage = StorageService.instance;

  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  late final DateTime _firstDay;
  late final DateTime _lastDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    _firstDay = DateTime.now().subtract(const Duration(days: 365));
    _lastDay = DateTime.now().add(const Duration(days: 365 * 2));
  }

  Future<void> _openEvent(CalendarEvent event) async {
    final uri = Uri.parse(event.url);
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('링크를 열 수 없습니다: ${event.url}')),
      );
    }
  }

  Future<void> _confirmDelete(DateTime day, CalendarEvent event) async {
    final choice = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('일정 삭제'),
        content: Text('"${event.title}" 일정을 어떻게 삭제할까요?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop('day_only'),
            child: const Text('해당 날짜만 삭제'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop('all'),
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: const Text('전체 일정 삭제'),
          ),
        ],
      ),
    );

    if (choice == 'day_only') {
      await _storage.deleteEventsForDate(day);
    } else if (choice == 'all') {
      await _storage.deleteAllEventsForBenefit(event.benefitId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedDay = _selectedDay ?? DateTime.now();

    return Scaffold(
      appBar: AppBar(title: const Text('혜택 달력'), centerTitle: true),
      body: ValueListenableBuilder<Map<String, List<CalendarEvent>>>(
        valueListenable: _storage.calendarNotifier,
        builder: (context, calendarMap, _) {
          return Column(
            children: [
              TableCalendar(
                locale: 'ko_KR',
                firstDay: _firstDay,
                lastDay: _lastDay,
                focusedDay: _focusedDay,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                onDaySelected: (selected, focused) {
                  setState(() {
                    _selectedDay = selected;
                    _focusedDay = focused;
                  });
                },
                headerStyle: const HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                ),
                calendarStyle: const CalendarStyle(
                  markersMaxCount: 1, // 여러 개 대신 항상 1개의 마커만 렌더링
                  markerDecoration: BoxDecoration(),
                  todayDecoration: BoxDecoration(
                    color: Color(0x337C4DFF),
                    shape: BoxShape.circle,
                  ),
                  selectedDecoration: BoxDecoration(
                    color: AppColors.accentPurple,
                    shape: BoxShape.circle,
                  ),
                ),
                eventLoader: (day) => _storage.getEventsForDate(day),
                calendarBuilders: CalendarBuilders(
                  // 세련된 시각화 마커: 여러 개의 점 대신 1개의 '보라색 형광펜 밑줄'
                  markerBuilder: (context, day, events) {
                    if (events.isEmpty) return const SizedBox.shrink();
                    return Positioned(
                      bottom: 4,
                      child: Container(
                        width: 20,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.accentPurple.withValues(alpha: 0.65),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: _EventListForDay(
                  day: selectedDay,
                  events: _storage.getEventsForDate(selectedDay),
                  onTapEvent: _openEvent,
                  onDeleteEvent: (event) => _confirmDelete(selectedDay, event),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _EventListForDay extends StatelessWidget {
  final DateTime day;
  final List<CalendarEvent> events;
  final void Function(CalendarEvent event) onTapEvent;
  final void Function(CalendarEvent event) onDeleteEvent;

  const _EventListForDay({
    required this.day,
    required this.events,
    required this.onTapEvent,
    required this.onDeleteEvent,
  });

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return Center(
        child: Text(
          '등록된 혜택 일정이 없습니다.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
              ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: events.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final event = events[index];
        return ListTile(
          leading: const Icon(Icons.link, color: AppColors.accentPurple),
          title: Text(event.title),
          subtitle: Text(
            event.url,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          onTap: () => onTapEvent(event), // 원본 웹사이트로 딥링크 이동
          trailing: IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.grey),
            onPressed: () => onDeleteEvent(event),
          ),
        );
      },
    );
  }
}