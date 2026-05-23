import 'package:flutter/material.dart';

class WorksheetPage
    extends StatelessWidget {
  const WorksheetPage({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
          AppBar(title: const Text(
        "Worksheet",
      )),

      body: ListView.builder(
        padding:
            const EdgeInsets.all(18),

        itemCount: 8,

        itemBuilder: (
          context,
          index,
        ) {
          return Container(
            margin:
                const EdgeInsets.only(
              bottom: 14,
            ),

            padding:
                const EdgeInsets.all(18),

            decoration: BoxDecoration(
              color: Colors.white,

              borderRadius:
                  BorderRadius.circular(
                22,
              ),
            ),

            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment
                      .start,

              children: [
                Text(
                  "Worksheet #${index + 1}",

                  style:
                      const TextStyle(
                    fontWeight:
                        FontWeight
                            .w700,

                    fontSize: 16,
                  ),
                ),

                const SizedBox(
                  height: 10,
                ),

                const Text(
                  "Daily drilling activity and progress worksheet.",
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}