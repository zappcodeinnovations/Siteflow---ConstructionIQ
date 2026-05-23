import 'package:flutter/material.dart';

class DiaryPage extends StatefulWidget {
  const DiaryPage({super.key});

  @override
  State<DiaryPage> createState() =>
      _DiaryPageState();
}

class _DiaryPageState
    extends State<DiaryPage> {
  final controller =
      TextEditingController();

  final List<String> notes = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Diary",
        ),
      ),

      body: Column(
        children: [
          Padding(
            padding:
                const EdgeInsets.all(18),

            child: TextField(
              controller: controller,

              maxLines: 5,

              decoration:
                  InputDecoration(
                hintText:
                    "Write today's work...",

                border:
                    OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(
                    18,
                  ),
                ),
              ),
            ),
          ),

          Padding(
            padding:
                const EdgeInsets.symmetric(
              horizontal: 18,
            ),

            child: SizedBox(
              width: double.infinity,

              child: ElevatedButton(
                onPressed: () {
                  if (controller.text
                      .isEmpty) {
                    return;
                  }

                  setState(() {
                    notes.insert(
                      0,
                      controller.text,
                    );

                    controller.clear();
                  });
                },

                child: const Text(
                  "Save Diary",
                ),
              ),
            ),
          ),

          const SizedBox(height: 18),

          Expanded(
            child: ListView.builder(
              itemCount:
                  notes.length,

              itemBuilder:
                  (context, index) {
                    return Container(
                      margin:
                          const EdgeInsets.symmetric(
                            horizontal:
                                18,
                            vertical: 8,
                          ),

                      padding:
                          const EdgeInsets.all(
                            18,
                          ),

                      decoration: BoxDecoration(
                        color:
                            Colors.white,

                        borderRadius:
                            BorderRadius.circular(
                              20,
                            ),
                      ),

                      child: Text(
                        notes[index],
                      ),
                    );
                  },
            ),
          ),
        ],
      ),
    );
  }
}