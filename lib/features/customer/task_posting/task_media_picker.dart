import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/task_posting_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import 'task_posting_models.dart';

/// Shared photo/video attachment strip for both posting methods: a row of
/// thumbnails plus an "Add" tile, capped at [kMaxTaskMedia]. Reused by the
/// manual flow's skippable media step and the voice chat's attach button.
///
/// Files are picked from the device camera/gallery and kept as local paths
/// only — nothing is uploaded anywhere, Phase 1 has no backend.
class TaskMediaPicker extends StatelessWidget {
  final List<TaskMediaItem> items;
  final ValueChanged<List<TaskMediaItem>> onChanged;

  const TaskMediaPicker({
    super.key,
    required this.items,
    required this.onChanged,
  });

  Future<void> _pick(
    BuildContext context, {
    required bool video,
    required ImageSource source,
  }) async {
    final picker = ImagePicker();
    try {
      final XFile? file = video
          ? await picker.pickVideo(source: source)
          : await picker.pickImage(source: source, imageQuality: 80);
      if (file == null) return;
      onChanged([...items, TaskMediaItem(path: file.path, isVideo: video)]);
    } catch (_) {
      // No camera/gallery available, or the user denied permission — fail
      // silently into a snackbar rather than crashing the flow.
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(TaskPostingStrings.mediaPickFailed)),
        );
      }
    }
  }

  void _remove(int index) {
    final next = [...items]..removeAt(index);
    onChanged(next);
  }

  void _openSourceSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: AppSpacing.md),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Text(TaskPostingStrings.mediaSheetTitle,
                  style: Theme.of(ctx).textTheme.titleMedium),
            ),
            const SizedBox(height: AppSpacing.sm),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined,
                  color: AppColors.purple700),
              title: const Text(TaskPostingStrings.mediaTakePhoto),
              onTap: () {
                Navigator.of(ctx).pop();
                _pick(context, video: false, source: ImageSource.camera);
              },
            ),
            ListTile(
              leading:
                  const Icon(Icons.photo_outlined, color: AppColors.purple700),
              title: const Text(TaskPostingStrings.mediaChoosePhoto),
              onTap: () {
                Navigator.of(ctx).pop();
                _pick(context, video: false, source: ImageSource.gallery);
              },
            ),
            ListTile(
              leading:
                  const Icon(Icons.videocam_outlined, color: AppColors.purple700),
              title: const Text(TaskPostingStrings.mediaRecordVideo),
              onTap: () {
                Navigator.of(ctx).pop();
                _pick(context, video: true, source: ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.video_library_outlined,
                  color: AppColors.purple700),
              title: const Text(TaskPostingStrings.mediaChooseVideo),
              onTap: () {
                Navigator.of(ctx).pop();
                _pick(context, video: true, source: ImageSource.gallery);
              },
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canAddMore = items.length < kMaxTaskMedia;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 88,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              for (var i = 0; i < items.length; i++)
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.sm),
                  child:
                      _MediaThumbnail(item: items[i], onRemove: () => _remove(i)),
                ),
              if (canAddMore)
                _AddMediaTile(onTap: () => _openSourceSheet(context)),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          canAddMore
              ? TaskPostingStrings.mediaHelperNote
              : TaskPostingStrings.mediaMaxReachedNote,
          style: theme.textTheme.bodySmall
              ?.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

class _MediaThumbnail extends StatelessWidget {
  final TaskMediaItem item;
  final VoidCallback onRemove;
  const _MediaThumbnail({required this.item, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 88,
      height: 88,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: item.isVideo
                ? Container(
                    width: 88,
                    height: 88,
                    color: AppColors.purple900,
                    alignment: Alignment.center,
                    child: const Icon(Icons.play_circle_fill,
                        color: Colors.white, size: 32),
                  )
                : Image.file(
                    File(item.path),
                    width: 88,
                    height: 88,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 88,
                      height: 88,
                      color: AppColors.lightSurface,
                      alignment: Alignment.center,
                      child: const Icon(Icons.broken_image_outlined,
                          color: AppColors.textSecondary),
                    ),
                  ),
          ),
          Positioned(
            top: -6,
            right: -6,
            child: Semantics(
              label: TaskPostingStrings.mediaRemoveLabel,
              button: true,
              child: Material(
                color: Colors.black54,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: onRemove,
                  child: const Padding(
                    padding: EdgeInsets.all(6),
                    child: Icon(Icons.close, color: Colors.white, size: 14),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddMediaTile extends StatelessWidget {
  final VoidCallback onTap;
  const _AddMediaTile({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: TaskPostingStrings.mediaAttachTooltip,
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            color: AppColors.blue100,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.purple700, width: 1.5),
          ),
          alignment: Alignment.center,
          child: const Icon(Icons.add_a_photo_outlined,
              color: AppColors.purple700, size: AppSizes.iconMd),
        ),
      ),
    );
  }
}
