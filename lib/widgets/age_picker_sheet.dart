import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

/// 나이를 스크롤 휠(피커) 형태로 선택하는 바텀시트.
/// 맞춤검색의 나이 입력, 마이페이지의 나이 수정에서 공용으로 사용한다.
/// 반환값이 null이면 사용자가 취소한 것.
Future<int?> showAgePickerSheet(
  BuildContext context, {
  required int initialAge,
  int minAge = 1,
  int maxAge = 100,
}) {
  final safeInitial = initialAge.clamp(minAge, maxAge);
  int selected = safeInitial;

  return showModalBottomSheet<int>(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('취소'),
                  ),
                  const Text(
                    '만 나이 선택',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(selected),
                    child: const Text(
                      '완료',
                      style: TextStyle(
                        color: AppColors.accentPurple,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(height: 1),
              SizedBox(
                height: 200,
                child: CupertinoPicker(
                  scrollController: FixedExtentScrollController(
                    initialItem: safeInitial - minAge,
                  ),
                  itemExtent: 40,
                  onSelectedItemChanged: (index) {
                    selected = minAge + index;
                  },
                  children: [
                    for (int age = minAge; age <= maxAge; age++)
                      Center(child: Text('$age세')),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}