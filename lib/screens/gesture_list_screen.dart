import 'package:flutter/material.dart';
import '../core/gesture_manager.dart';
import '../core/language_manager.dart';
import '../widgets/gesture_card.dart';
import '../utils/logger.dart';

class GestureListScreen extends StatefulWidget {
  final LanguageManager languageManager;
  final Function(HandGesture) onGestureSelected;

  const GestureListScreen({
    super.key,
    required this.languageManager,
    required this.onGestureSelected,
  });

  @override
  State<GestureListScreen> createState() => _GestureListScreenState();
}

class _GestureListScreenState extends State<GestureListScreen> {
  List<HandGesture> _gestures = [];
  List<HandGesture> _filteredGestures = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadGestures();
    _searchController.addListener(_filterGestures);
  }

  void _loadGestures() {
    setState(() {
      _gestures = GestureManager.getDefaultGestures();
      _filteredGestures = _gestures;
    });
    AppLogger.info('Loaded ${_gestures.length} gestures');
  }

  void _filterGestures() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredGestures = _gestures.where((gesture) =>
        gesture.name.toLowerCase().contains(query) ||
        gesture.description.toLowerCase().contains(query)
      ).toList();
    });
  }

  void _showAddGestureDialog() {
    showDialog(
      context: context,
      builder: (context) => AddGestureDialog(
        onGestureAdded: (gesture) {
          setState(() {
            GestureManager.addCustomGesture(gesture);
            _gestures = GestureManager.getDefaultGestures();
            _filteredGestures = _gestures;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gesture "${gesture.name}" added successfully')),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.languageManager.getLocalizedText('gestures')),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddGestureDialog,
            tooltip: 'Add Custom Gesture',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search gestures...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          Expanded(
            child: _filteredGestures.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.gesture,
                          size: 64,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No gestures found',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Try searching or add a custom gesture',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredGestures.length,
                    itemBuilder: (context, index) {
                      final gesture = _filteredGestures[index];
                      return GestureCard(
                        gesture: gesture,
                        onTap: () => widget.onGestureSelected(gesture),
                        onEdit: () => _showEditGestureDialog(gesture),
                        onDelete: () => _showDeleteConfirmation(gesture),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showEditGestureDialog(HandGesture gesture) {
    showDialog(
      context: context,
      builder: (context) => AddGestureDialog(
        gesture: gesture,
        onGestureAdded: (updatedGesture) {
          setState(() {
            GestureManager.removeGesture(gesture.id);
            GestureManager.addCustomGesture(updatedGesture);
            _gestures = GestureManager.getDefaultGestures();
            _filteredGestures = _gestures;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gesture "${updatedGesture.name}" updated')),
          );
        },
      ),
    );
  }

  void _showDeleteConfirmation(HandGesture gesture) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Gesture'),
        content: Text('Are you sure you want to delete "${gesture.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                GestureManager.removeGesture(gesture.id);
                _gestures = GestureManager.getDefaultGestures();
                _filteredGestures = _gestures;
              });
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Gesture "${gesture.name}" deleted')),
              );
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

class AddGestureDialog extends StatefulWidget {
  final HandGesture? gesture;
  final Function(HandGesture) onGestureAdded;

  const AddGestureDialog({
    super.key,
    this.gesture,
    required this.onGestureAdded,
  });

  @override
  State<AddGestureDialog> createState() => _AddGestureDialogState();
}

class _AddGestureDialogState extends State<AddGestureDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _arduinoCodeController = TextEditingController();
  final _ttsMessageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.gesture != null) {
      _nameController.text = widget.gesture!.name;
      _descriptionController.text = widget.gesture!.description;
      _arduinoCodeController.text = widget.gesture!.arduinoCode;
      _ttsMessageController.text = widget.gesture!.ttsMessage ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.gesture == null ? 'Add Custom Gesture' : 'Edit Gesture'),
      content: SizedBox(
        width: double.maxFinite,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Gesture Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a gesture name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a description';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _arduinoCodeController,
                  decoration: const InputDecoration(
                    labelText: 'Arduino Code',
                    border: OutlineInputBorder(),
                    helperText: 'Enter your Arduino code here',
                  ),
                  maxLines: 8,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter Arduino code';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _ttsMessageController,
                  decoration: const InputDecoration(
                    labelText: 'TTS Message (Optional)',
                    border: OutlineInputBorder(),
                    helperText: 'Message to speak when gesture is detected',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final gesture = HandGesture(
                id: widget.gesture?.id ?? _nameController.text.toLowerCase().replaceAll(' ', '_'),
                name: _nameController.text,
                description: _descriptionController.text,
                arduinoCode: _arduinoCodeController.text,
                ttsMessage: _ttsMessageController.text.isEmpty ? null : _ttsMessageController.text,
              );
              widget.onGestureAdded(gesture);
              Navigator.of(context).pop();
            }
          },
          child: const Text('Save'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _arduinoCodeController.dispose();
    _ttsMessageController.dispose();
    super.dispose();
  }
}
