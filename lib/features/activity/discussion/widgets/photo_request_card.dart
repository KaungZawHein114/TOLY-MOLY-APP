import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../activity_chat.dart' show ActivityRole;
import '../discussion_models.dart';
import 'discussion_card.dart';

/// "Please send photos of the broken motor."
///
/// The answering side taps one big button and placeholder thumbnails appear.
/// Real camera/gallery pickers arrive with the Phase-2 media layer; the card's
/// shape (`data['photos']`) already matches what that will fill in.
class PhotoRequestCard extends StatelessWidget {
  final DiscussionItem item;
  final ActivityRole viewerRole;
  final bool highlighted;
  final ValueChanged<DiscussionItem> onUpdate;
  final VoidCallback? onDemoAnswer;

  const PhotoRequestCard({
    super.key,
    required this.item,
    required this.viewerRole,
    required this.onUpdate,
    this.highlighted = false,
    this.onDemoAnswer,
  });

  void _upload() {
    onUpdate(
      item.withData({'photos': item.photoCount + 2}).copyWith(
          status: DiscussionStatus.answered),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final photos = item.photoCount;

    return DiscussionCard(
      item: item,
      viewerRole: viewerRole,
      highlighted: highlighted,
      onDemoAnswer: onDemoAnswer,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (photos > 0) ...[
            SizedBox(
              height: 84,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: photos,
                separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
                itemBuilder: (_, index) => Semantics(
                  image: true,
                  label: 'ပေးပို့ထားသော ဓာတ်ပုံ ${index + 1}',
                  child: Container(
                    width: 84,
                    decoration: BoxDecoration(
                      gradient: AppColors.guidanceSurfaceGradient,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: const Icon(
                      Icons.image_outlined,
                      color: AppColors.purple500,
                      size: AppSizes.iconLg,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            DiscussionResultNote(
              icon: Icons.check_circle_rounded,
              text: 'ဓာတ်ပုံ $photos ပုံ လက်ခံရရှိပါပြီ',
              color: AppColors.tealDark,
            ),
          ],
          if (item.isMyTurn(viewerRole)) ...[
            if (photos > 0) const SizedBox(height: AppSpacing.sm),
            FilledButton.icon(
              onPressed: _upload,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                backgroundColor: AppColors.purple700,
                foregroundColor: AppColors.onBrand,
              ),
              icon: const Icon(Icons.add_a_photo_outlined),
              label: const Text('ဓာတ်ပုံ တင်ရန်'),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'ကင်မရာ သို့မဟုတ် ပုံတွဲထဲက ရွေးနိုင်ပါသည်။',
              style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ],
      ),
    );
  }
}
