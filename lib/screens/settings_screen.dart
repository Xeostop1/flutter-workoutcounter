import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool isFemale = true;
  bool isDelayOn = false;
  int restSeconds = 10;

  final List<int> restValues = List.generate(20, (i) => i + 1); // 1~20초

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 16),
              const Text('Voice', style: TextStyle(fontSize: 18)),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  _buildVoiceButton(true, '여성'),
                  const SizedBox(width: 16),
                  _buildVoiceButton(false, '남성'),
                ],
              ),
              const SizedBox(height: 40),

              // ✅ Delay
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Delay', style: TextStyle(fontSize: 18)),
                  Switch(
                    value: isDelayOn,
                    onChanged: (val) {
                      setState(() {
                        isDelayOn = val;
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 40),

              // ✅ 휴식 휠피커
              const Text('휴식', style: TextStyle(fontSize: 18)),
              const SizedBox(height: 12),
              SizedBox(
                height: 120,
                child: CupertinoPicker(
                  itemExtent: 40,
                  scrollController: FixedExtentScrollController(
                    initialItem: restValues.indexOf(restSeconds),
                  ),
                  onSelectedItemChanged: (index) {
                    setState(() {
                      restSeconds = restValues[index];
                    });
                  },
                  children: restValues
                      .map((val) => Center(
                    child: Text('$val초', style: const TextStyle(fontSize: 20)),
                  ))
                      .toList(),
                ),
              ),
              const Spacer(),

              // ✅ 저장 버튼
              Center(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(32),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                  ),
                  onPressed: () {
                    // TODO: 저장 기능 구현
                  },
                  child: const Text('Save', style: TextStyle(fontSize: 18)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ✅ Voice 선택 버튼 위젯
  Widget _buildVoiceButton(bool female, String label) {
    final isSelected = isFemale == female;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            isFemale = female;
          });
        },
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            color: isSelected ? Colors.black : Colors.transparent,
            border: Border.all(color: Colors.black),
            borderRadius: BorderRadius.circular(24),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.black,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }
}
