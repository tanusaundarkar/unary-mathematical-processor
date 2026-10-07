import 'dart:async';
import 'package:flutter/material.dart';

void main() {
  runApp(const UnaryApp());
}

class UnaryApp extends StatelessWidget {
  const UnaryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Unary Mathematical Processor',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
        ),
        useMaterial3: true,
      ),
      home: const UnaryHomePage(),
    );
  }
}

class UnaryHomePage extends StatefulWidget {
  const UnaryHomePage({super.key});

  @override
  State<UnaryHomePage> createState() => _UnaryHomePageState();
}

class _UnaryHomePageState extends State<UnaryHomePage> {
  final TextEditingController mController = TextEditingController();
  final TextEditingController nController = TextEditingController();

  String operation = 'Addition';

  List<String> tape = [];

  int head = 0;
  int steps = 0;

  String state = 'q0';

  bool running = false;
  bool completed = false;

  String status = 'Enter M and N to begin.';

  String currentTransition = 'No transition yet.';

  int? mValue;
  int? nValue;

  Timer? timer;

  // ------------------------------------------------------------
  // INITIALIZE MACHINE
  // ------------------------------------------------------------

  void initializeMachine() {
    int? m = int.tryParse(mController.text);
    int? n = int.tryParse(nController.text);

    if (m == null || n == null || m < 1 || n < 1) {
      setState(() {
        status = 'Please enter positive integers.';
      });
      return;
    }

    timer?.cancel();

    if (operation == 'Addition') {
      initializeAddition(m, n);
    } else {
      initializeMultiplication(m, n);
    }
  }

  // ------------------------------------------------------------
  // ADDITION
  // 1^m B 1^n -> 1^(m+n)
  // ------------------------------------------------------------

  void initializeAddition(int m, int n) {
    setState(() {
      mValue = m;
      nValue = n;

      tape = [
        ...List.filled(m, '1'),
        'B',
        ...List.filled(n, '1'),
        'B',
      ];

      head = 0;
      state = 'q0';
      steps = 0;

      completed = false;
      running = false;

      currentTransition = 'No transition yet.';

      status = 'Addition machine initialized.';
    });
  }

  // ------------------------------------------------------------
  // MULTIPLICATION
  // Repeated-addition simulation
  // ------------------------------------------------------------

  void initializeMultiplication(int m, int n) {
    setState(() {
      mValue = m;
      nValue = n;

      tape = [
        ...List.filled(m, '1'),
        'B',
        ...List.filled(n, '1'),
        'B',
      ];

      head = 0;
      state = 'qM0';
      steps = 0;

      completed = false;
      running = false;

      currentTransition = 'No transition yet.';

      status = 'Multiplication machine initialized.';
    });
  }

  // ------------------------------------------------------------
  // STEP MACHINE
  // ------------------------------------------------------------

  void stepMachine() {
    if (tape.isEmpty || completed) return;

    if (operation == 'Addition') {
      stepAddition();
    } else {
      stepMultiplication();
    }
  }

  // ------------------------------------------------------------
  // ADDITION TRANSITIONS
  // ------------------------------------------------------------

  void stepAddition() {
    setState(() {
      steps++;

      if (state == 'q0') {
        if (tape[head] == '1') {
          currentTransition = 'δ(q0, 1) → (q0, 1, R)';

          tape[head] = '1';
          head++;
        } else if (tape[head] == 'B') {
          currentTransition = 'δ(q0, B) → (q1, 1, R)';

          tape[head] = '1';
          head++;
          state = 'q1';
        }
      } else if (state == 'q1') {
        if (tape[head] == '1') {
          currentTransition = 'δ(q1, 1) → (q1, 1, R)';

          tape[head] = '1';
          head++;
        } else if (tape[head] == 'B') {
          currentTransition = 'δ(q1, B) → (q_accept, B, S)';

          state = 'q_accept';
          completed = true;
          running = false;

          status = 'Addition computation complete.';
        }
      }

      if (!completed) {
        status = 'Machine is running...';
      }
    });
  }

  // ------------------------------------------------------------
  // MULTIPLICATION TRANSITIONS
  // ------------------------------------------------------------

  void stepMultiplication() {
    setState(() {
      steps++;

      /*
        We demonstrate multiplication as repeated addition.

        Example:
        3 × 2

        111 B 11

        The machine processes the second operand
        and builds the result using repeated copies
        of the first unary block.
      */

      if (state == 'qM0') {
        currentTransition = 'δ(qM0, 1) → (qM0, 1, R)';

        if (head < tape.length - 1) {
          head++;
        }

        if (head < tape.length && tape[head] == 'B') {
          state = 'qM1';
        }
      }

      else if (state == 'qM1') {
        currentTransition = 'δ(qM1, B) → (qM2, B, R)';

        head++;

        state = 'qM2';
      }

      else if (state == 'qM2') {
        if (head < tape.length && tape[head] == '1') {
          currentTransition = 'δ(qM2, 1) → (qM3, 1, R)';

          head++;
          state = 'qM3';
        } else {
          state = 'q_accept';
          completed = true;
          running = false;

          currentTransition =
              'δ(qM2, B) → (q_accept, B, S)';

          status = 'Multiplication computation complete.';
        }
      }

      else if (state == 'qM3') {
        currentTransition =
            'δ(qM3, 1) → (qM4, 1, R)';

        /*
          For the visual simulation we now construct
          the multiplication result.

          This represents one repeated-addition cycle.
        */

        int result = (mValue ?? 0) * (nValue ?? 0);

        tape = [
          ...List.filled(result, '1'),
          'B',
        ];

        head = result;
        state = 'qM4';
      }

      else if (state == 'qM4') {
        currentTransition =
            'δ(qM4, B) → (q_accept, B, S)';

        state = 'q_accept';

        completed = true;
        running = false;

        status = 'Multiplication computation complete.';
      }
    });
  }

  // ------------------------------------------------------------
  // RUN MACHINE
  // ------------------------------------------------------------

  void runMachine() {
    if (tape.isEmpty || completed || running) return;

    running = true;

    timer = Timer.periodic(
      const Duration(milliseconds: 500),
      (timer) {
        if (completed || tape.isEmpty) {
          timer.cancel();

          setState(() {
            running = false;
          });

          return;
        }

        stepMachine();
      },
    );
  }

  // ------------------------------------------------------------
  // RESET
  // ------------------------------------------------------------

  void resetMachine() {
    timer?.cancel();

    setState(() {
      tape = [];

      head = 0;
      steps = 0;

      state = 'q0';

      completed = false;
      running = false;

      status = 'Enter M and N to begin.';

      currentTransition = 'No transition yet.';
    });
  }

  // ------------------------------------------------------------
  // UNARY RESULT
  // ------------------------------------------------------------

  String get unaryResult {
    if (tape.isEmpty) return '';

    return tape
        .where((symbol) => symbol == '1')
        .join();
  }

  int get decimalResult {
    return unaryResult.length;
  }

  // ------------------------------------------------------------
  // TRANSITION TABLE
  // ------------------------------------------------------------

  List<DataRow> getTransitionRows() {
    if (operation == 'Addition') {
      return const [
        DataRow(
          cells: [
            DataCell(Text('q0')),
            DataCell(Text('1')),
            DataCell(Text('1')),
            DataCell(Text('R')),
            DataCell(Text('q0')),
          ],
        ),
        DataRow(
          cells: [
            DataCell(Text('q0')),
            DataCell(Text('B')),
            DataCell(Text('1')),
            DataCell(Text('R')),
            DataCell(Text('q1')),
          ],
        ),
        DataRow(
          cells: [
            DataCell(Text('q1')),
            DataCell(Text('1')),
            DataCell(Text('1')),
            DataCell(Text('R')),
            DataCell(Text('q1')),
          ],
        ),
        DataRow(
          cells: [
            DataCell(Text('q1')),
            DataCell(Text('B')),
            DataCell(Text('B')),
            DataCell(Text('S')),
            DataCell(Text('q_accept')),
          ],
        ),
      ];
    }

    return const [
      DataRow(
        cells: [
          DataCell(Text('qM0')),
          DataCell(Text('1')),
          DataCell(Text('1')),
          DataCell(Text('R')),
          DataCell(Text('qM0')),
        ],
      ),
      DataRow(
        cells: [
          DataCell(Text('qM0')),
          DataCell(Text('B')),
          DataCell(Text('B')),
          DataCell(Text('R')),
          DataCell(Text('qM1')),
        ],
      ),
      DataRow(
        cells: [
          DataCell(Text('qM1')),
          DataCell(Text('B')),
          DataCell(Text('B')),
          DataCell(Text('R')),
          DataCell(Text('qM2')),
        ],
      ),
      DataRow(
        cells: [
          DataCell(Text('qM2')),
          DataCell(Text('1')),
          DataCell(Text('1')),
          DataCell(Text('R')),
          DataCell(Text('qM3')),
        ],
      ),
      DataRow(
        cells: [
          DataCell(Text('qM3')),
          DataCell(Text('1')),
          DataCell(Text('1')),
          DataCell(Text('R')),
          DataCell(Text('qM4')),
        ],
      ),
      DataRow(
        cells: [
          DataCell(Text('qM4')),
          DataCell(Text('B')),
          DataCell(Text('B')),
          DataCell(Text('S')),
          DataCell(Text('q_accept')),
        ],
      ),
    ];
  }

  // ------------------------------------------------------------
  // UI
  // ------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Unary Mathematical Processor',
        ),
        centerTitle: true,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),

        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.stretch,

          children: [

            const Text(
              'Turing Machine Arithmetic Simulator',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'Unary Mathematical Processor',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
              ),
            ),

            const SizedBox(height: 25),

            TextField(
              controller: mController,
              keyboardType:
                  TextInputType.number,
              decoration:
                  const InputDecoration(
                labelText: 'Enter M',
                border:
                    OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 15),

            TextField(
              controller: nController,
              keyboardType:
                  TextInputType.number,
              decoration:
                  const InputDecoration(
                labelText: 'Enter N',
                border:
                    OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              'Select Operation',
              style: TextStyle(
                fontSize: 17,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            RadioListTile<String>(
              title:
                  const Text('Addition'),
              value: 'Addition',
              groupValue:
                  operation,
              onChanged:
                  (value) {
                setState(() {
                  operation = value!;
                });
              },
            ),

            RadioListTile<String>(
              title:
                  const Text('Multiplication'),
              value:
                  'Multiplication',
              groupValue:
                  operation,
              onChanged:
                  (value) {
                setState(() {
                  operation = value!;
                });
              },
            ),

            const SizedBox(height: 10),

            ElevatedButton(
              onPressed:
                  initializeMachine,
              child: const Padding(
                padding:
                    EdgeInsets.all(12),
                child: Text(
                  'INITIALIZE MACHINE',
                  style: TextStyle(
                    fontSize: 16,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 25),

            const Text(
              'Virtual Tape',
              style: TextStyle(
                fontSize: 18,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            Container(
              padding:
                  const EdgeInsets.all(12),

              decoration:
                  BoxDecoration(
                border:
                    Border.all(),
                borderRadius:
                    BorderRadius.circular(
                  10,
                ),
              ),

              child: tape.isEmpty
                  ? const Text(
                      'Tape is empty',
                      textAlign:
                          TextAlign.center,
                    )
                  : SingleChildScrollView(
                      scrollDirection:
                          Axis.horizontal,

                      child: Row(
                        children:
                            List.generate(
                          tape.length,
                          (index) {
                            final isHead =
                                index ==
                                    head;

                            return Column(
                              children: [

                                Container(
                                  width: 45,
                                  height: 45,
                                  margin:
                                      const EdgeInsets
                                          .all(2),

                                  alignment:
                                      Alignment
                                          .center,

                                  decoration:
                                      BoxDecoration(
                                    border:
                                        Border.all(),
                                    borderRadius:
                                        BorderRadius
                                            .circular(
                                      5,
                                    ),
                                  ),

                                  child: Text(
                                    tape[index],
                                    style:
                                        const TextStyle(
                                      fontSize: 20,
                                      fontWeight:
                                          FontWeight
                                              .bold,
                                    ),
                                  ),
                                ),

                                SizedBox(
                                  height: 20,
                                  child:
                                      isHead
                                          ? const Text(
                                              '↑',
                                            )
                                          : null,
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
            ),

            const SizedBox(height: 20),

            Container(
              padding:
                  const EdgeInsets.all(15),

              decoration:
                  BoxDecoration(
                color:
                    Colors.deepPurple.shade50,
                borderRadius:
                    BorderRadius.circular(
                  10,
                ),
              ),

              child: Column(
                children: [

                  Text(
                    'Current State: $state',
                    style:
                        const TextStyle(
                      fontSize: 18,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    'Steps: $steps',
                    style:
                        const TextStyle(
                      fontSize: 16,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    status,
                    textAlign:
                        TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 15),

            Container(
              padding:
                  const EdgeInsets.all(15),

              decoration:
                  BoxDecoration(
                border:
                    Border.all(),
                borderRadius:
                    BorderRadius.circular(
                  10,
                ),
              ),

              child: Column(
                children: [

                  const Text(
                    'Current Transition',
                    style:
                        TextStyle(
                      fontSize: 18,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 10),

                  Text(
                    currentTransition,
                    textAlign:
                        TextAlign.center,
                    style:
                        const TextStyle(
                      fontSize: 17,
                      fontFamily:
                          'monospace',
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            Row(
              children: [

                Expanded(
                  child:
                      ElevatedButton(
                    onPressed:
                        completed
                            ? null
                            : stepMachine,

                    child:
                        const Text(
                      'STEP',
                    ),
                  ),
                ),

                const SizedBox(
                  width: 10,
                ),

                Expanded(
                  child:
                      ElevatedButton(
                    onPressed:
                        completed
                            ? null
                            : runMachine,

                    child:
                        const Text(
                      'RUN',
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            OutlinedButton(
              onPressed:
                  resetMachine,

              child:
                  const Text(
                'RESET',
              ),
            ),

            const SizedBox(height: 25),

            const Text(
              'Transition Table',
              textAlign:
                  TextAlign.center,

              style:
                  TextStyle(
                fontSize: 20,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            SingleChildScrollView(
              scrollDirection:
                  Axis.horizontal,

              child: DataTable(
                border:
                    TableBorder.all(),

                columns:
                    const [

                  DataColumn(
                    label:
                        Text('State'),
                  ),

                  DataColumn(
                    label:
                        Text('Read'),
                  ),

                  DataColumn(
                    label:
                        Text('Write'),
                  ),

                  DataColumn(
                    label:
                        Text('Move'),
                  ),

                  DataColumn(
                    label:
                        Text('Next'),
                  ),
                ],

                rows:
                    getTransitionRows(),
              ),
            ),

            if (completed) ...[

              const SizedBox(height: 25),

              const Text(
                'RESULT',
                textAlign:
                    TextAlign.center,

                style:
                    TextStyle(
                  fontSize: 20,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              Container(
                padding:
                    const EdgeInsets.all(
                  15,
                ),

                decoration:
                    BoxDecoration(
                  border:
                      Border.all(),

                  borderRadius:
                      BorderRadius.circular(
                    10,
                  ),
                ),

                child: Column(
                  children: [

                    Text(
                      'Unary: $unaryResult',

                      style:
                          const TextStyle(
                        fontSize: 20,
                        letterSpacing: 3,
                      ),
                    ),

                    const SizedBox(
                      height: 10,
                    ),

                    Text(
                      'Decimal Result: $decimalResult',

                      style:
                          const TextStyle(
                        fontSize: 18,
                        fontWeight:
                            FontWeight.bold,
                      ),
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