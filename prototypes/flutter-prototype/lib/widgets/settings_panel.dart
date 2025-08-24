import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/media_provider.dart';

class SettingsPanel extends StatelessWidget {
  const SettingsPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MediaProvider>();
    final theme = Theme.of(context);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '転送設定',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 24),
            
            // 出力先
            Text(
              '出力先',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            _DestinationOption(
              value: 'local',
              groupValue: provider.destination,
              icon: Icons.storage,
              label: 'ローカルストレージ',
              onChanged: provider.setDestination,
            ),
            const SizedBox(height: 8),
            _DestinationOption(
              value: 'cloud',
              groupValue: provider.destination,
              icon: Icons.cloud,
              label: 'クラウドストレージ',
              onChanged: provider.setDestination,
            ),
            
            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 24),
            
            // 整理ルール
            Text(
              '整理ルール',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            _RuleCheckbox(
              value: provider.organizeByDate,
              onChanged: provider.setOrganizeByDate,
              icon: Icons.calendar_today,
              label: '日付別に整理',
            ),
            const SizedBox(height: 8),
            _RuleCheckbox(
              value: provider.organizeByDevice,
              onChanged: provider.setOrganizeByDevice,
              icon: Icons.devices,
              label: 'デバイス別に整理',
            ),
            const SizedBox(height: 8),
            _RuleCheckbox(
              value: provider.detectDuplicates,
              onChanged: provider.setDetectDuplicates,
              icon: Icons.find_in_page,
              label: '重複検出',
            ),
            
            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 24),
            
            // 処理実行ボタン
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: provider.files.isEmpty || provider.status == ProcessingStatus.processing
                    ? null
                    : () {
                        provider.processFiles();
                      },
                icon: provider.status == ProcessingStatus.processing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.play_arrow),
                label: Text(
                  provider.status == ProcessingStatus.processing
                      ? '処理中...'
                      : '処理開始',
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            
            // プログレスバー
            if (provider.status == ProcessingStatus.processing) ...[
              const SizedBox(height: 16),
              LinearProgressIndicator(
                value: provider.progress,
                minHeight: 8,
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  '${(provider.progress * 100).toInt()}%',
                  style: theme.textTheme.bodySmall,
                ),
              ),
            ],
            
            // 完了メッセージ
            if (provider.status == ProcessingStatus.completed) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green),
                    const SizedBox(width: 8),
                    Text(
                      '処理が完了しました！',
                      style: TextStyle(color: Colors.green[700]),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DestinationOption extends StatelessWidget {
  final String value;
  final String groupValue;
  final IconData icon;
  final String label;
  final Function(String) onChanged;
  
  const _DestinationOption({
    required this.value,
    required this.groupValue,
    required this.icon,
    required this.label,
    required this.onChanged,
  });
  
  @override
  Widget build(BuildContext context) {
    final isSelected = value == groupValue;
    final theme = Theme.of(context);
    
    return InkWell(
      onTap: () => onChanged(value),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.dividerColor,
          ),
        ),
        child: Row(
          children: [
            Radio<String>(
              value: value,
              groupValue: groupValue,
              onChanged: (value) => onChanged(value!),
            ),
            Icon(icon, size: 20),
            const SizedBox(width: 8),
            Text(label),
          ],
        ),
      ),
    );
  }
}

class _RuleCheckbox extends StatelessWidget {
  final bool value;
  final Function(bool) onChanged;
  final IconData icon;
  final String label;
  
  const _RuleCheckbox({
    required this.value,
    required this.onChanged,
    required this.icon,
    required this.label,
  });
  
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Checkbox(
              value: value,
              onChanged: (value) => onChanged(value!),
            ),
            Icon(icon, size: 20),
            const SizedBox(width: 8),
            Text(label),
          ],
        ),
      ),
    );
  }
}