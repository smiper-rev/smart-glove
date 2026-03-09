import 'package:flutter/material.dart';
import '../services/bluetooth_service.dart' as local;
import '../core/language_manager.dart';
import '../core/constants.dart';
import '../theme/app_theme.dart';
import '../utils/logger.dart';

class TtsPlayer extends StatelessWidget {
  final local.BluetoothService bluetoothService;
  final LanguageManager languageManager;

  const TtsPlayer({
    super.key,
    required this.bluetoothService,
    required this.languageManager,
  });

  @override
  Widget build(BuildContext context) {
    AppLogger.ui('Building TTS Player widget');
    
    return Card(
      margin: const EdgeInsets.all(8.0),
      elevation: 10,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: StreamBuilder<TtsState>(
          stream: bluetoothService.ttsState,
          initialData: TtsState.stopped,
          builder: (context, snapshot) {
            final isSpeaking = snapshot.data == TtsState.playing;
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildStatusIndicator(context, isSpeaking),
                const SizedBox(height: 16),
                _buildCurrentText(context),
                if (isSpeaking) ...[
                  const SizedBox(height: 16),
                  _buildStopButton(context),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatusIndicator(BuildContext context, bool isSpeaking) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          isSpeaking ? Icons.volume_up : Icons.volume_off,
          color: isSpeaking ? AppTheme.secondaryColor : Colors.grey,
        ),
        const SizedBox(width: 8),
        Text(
          isSpeaking
              ? languageManager.getLocalizedText('speaking')
              : languageManager.getLocalizedText('waiting'),
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: isSpeaking ? AppTheme.secondaryColor : Colors.grey,
              ),
        ),
      ],
    );
  }

  Widget _buildCurrentText(BuildContext context) {
    return StreamBuilder<String?>(
      stream: bluetoothService.currentSpokenText,
      builder: (context, snapshot) {
        final text = snapshot.data ?? "";
        return Text(
          text,
          style: Theme.of(context).textTheme.headlineMedium,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        );
      },
    );
  }

  Widget _buildStopButton(BuildContext context) {
    return ElevatedButton.icon(
      icon: const Icon(Icons.stop_circle_outlined),
      label: Text(languageManager.getLocalizedText('stopSpeaking')),
      onPressed: () => bluetoothService.stopSpeaking(),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.errorColor,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
      ),
    );
  }
}
