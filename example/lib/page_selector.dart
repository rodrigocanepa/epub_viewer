import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PageSelector extends StatefulWidget {
  final int startValue;
  final int maxValue;
  final ValueChanged<int> onPageChange;

  PageSelector({
    required this.startValue,
    required this.maxValue,
    required this.onPageChange,
  });

  @override
  _PageSelectorState createState() => _PageSelectorState();
}

class _PageSelectorState extends State<PageSelector> {
  late int _currentSliderValue;
  late TextEditingController _textController;
  late double _maxSliderValue;

  @override
  void initState() {
    super.initState();
    _currentSliderValue = widget.startValue;
    _maxSliderValue = widget.maxValue.toDouble();
    _textController = TextEditingController(text: widget.startValue.toString());
  }

  void _onTextFieldChanged(String value) {
    if (value.isNotEmpty) {
      final newValue = int.tryParse(value);
      if (newValue != null && newValue >= 1 && newValue <= _maxSliderValue) {
        setState(() {
          _currentSliderValue = newValue;
        });
        widget.onPageChange(_currentSliderValue);
      } else {
        _textController.text = _currentSliderValue.toString();
        _textController.selection = TextSelection.fromPosition(
          TextPosition(offset: _textController.text.length),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[200],
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Slider(
            value: _currentSliderValue.toDouble(),
            max: _maxSliderValue,
            divisions: 5,
            label: _currentSliderValue.round().toString(),
            onChanged: (double value) {
              setState(() {
                _currentSliderValue = value.toInt();
                _textController.text = _currentSliderValue.toString();
              });
            },
            onChangeEnd: (double value) {
              widget.onPageChange(value.toInt());
            },
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 80,
            child: TextField(
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Page',
              ),
              controller: _textController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                TextInputFormatter.withFunction((oldValue, newValue) {
                  if (newValue.text.isEmpty) {
                    return newValue;
                  }
                  final newInt = int.tryParse(newValue.text);
                  if (newInt != null &&
                      newInt >= 1 &&
                      newInt <= _maxSliderValue) {
                    return newValue;
                  }
                  return oldValue;
                }),
              ],
              onChanged: _onTextFieldChanged,
              onSubmitted: (value) {
                final newValue = int.tryParse(value);
                if (newValue != null) {
                  setState(() {
                    _currentSliderValue = newValue;
                  });
                  widget.onPageChange(newValue);
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
