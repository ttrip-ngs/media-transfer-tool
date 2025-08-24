import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../providers/media_provider.dart';
import '../widgets/file_selection_card.dart';
import '../widgets/statistics_cards.dart';
import '../widgets/file_list_view.dart';
import '../widgets/settings_panel.dart';
import '../widgets/gradient_app_bar.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const GradientAppBar(
        title: 'メディア転送ツール - Flutter版',
        subtitle: 'デスクトップアプリケーション',
      ),
      body: Consumer<MediaProvider>(
        builder: (context, provider, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ファイル選択エリア
                const FileSelectionCard()
                  .animate()
                  .fadeIn(duration: 600.ms)
                  .slideY(begin: 0.2, end: 0),
                
                const SizedBox(height: 24),
                
                // 統計情報
                if (provider.files.isNotEmpty) ...[
                  const StatisticsCards()
                    .animate()
                    .fadeIn(delay: 200.ms, duration: 600.ms)
                    .slideY(begin: 0.2, end: 0),
                  
                  const SizedBox(height: 24),
                  
                  // メインコンテンツ
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ファイルリスト
                      Expanded(
                        flex: 2,
                        child: const FileListView()
                          .animate()
                          .fadeIn(delay: 400.ms, duration: 600.ms)
                          .slideX(begin: -0.2, end: 0),
                      ),
                      
                      const SizedBox(width: 24),
                      
                      // 設定パネル
                      Expanded(
                        flex: 1,
                        child: const SettingsPanel()
                          .animate()
                          .fadeIn(delay: 600.ms, duration: 600.ms)
                          .slideX(begin: 0.2, end: 0),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}