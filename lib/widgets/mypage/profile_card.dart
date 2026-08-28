import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class ProfileCard extends StatefulWidget {
  final String nickname;
  final int age;
  final String? profileImageBase64;
  final bool isPickingImage;
  final VoidCallback onTapChangePhoto;
  final VoidCallback onTapEditNickname;

  const ProfileCard({
    super.key,
    required this.nickname,
    required this.age,
    required this.profileImageBase64,
    required this.isPickingImage,
    required this.onTapChangePhoto,
    required this.onTapEditNickname,
  });

  @override
  State<ProfileCard> createState() => _ProfileCardState();
}

class _ProfileCardState extends State<ProfileCard> {
  ImageProvider? _backgroundImage;

  @override
  void initState() {
    super.initState();
    _updateImage();
  }

  @override
  void didUpdateWidget(covariant ProfileCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.profileImageBase64 != widget.profileImageBase64) {
      _updateImage();
    }
  }

  void _updateImage() {
    if (widget.profileImageBase64 != null && widget.profileImageBase64!.isNotEmpty) {
      try {
        _backgroundImage = MemoryImage(base64Decode(widget.profileImageBase64!));
      } catch (_) {
        _backgroundImage = null;
      }
    } else {
      _backgroundImage = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: AppColors.accentPurple.withValues(alpha: 0.12),
                  backgroundImage: _backgroundImage,
                  child: _backgroundImage == null
                      ? const Icon(Icons.person, size: 40, color: AppColors.accentPurple)
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: widget.isPickingImage ? null : widget.onTapChangePhoto,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: AppColors.accentPurple,
                        shape: BoxShape.circle,
                      ),
                      child: widget.isPickingImage
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.camera_alt,
                              size: 14, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          widget.nickname.isEmpty ? '이름 없음' : widget.nickname,
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, size: 18, color: Colors.grey),
                        onPressed: widget.onTapEditNickname,
                        tooltip: '닉네임 수정',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '만 ${widget.age}세',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
