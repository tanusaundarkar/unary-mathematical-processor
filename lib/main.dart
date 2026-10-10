import 'dart:async';
import 'package:flutter/material.dart';

void main() => runApp(const UnaryApp());

const Color ink = Color(0xFF30256B);
const Color violet = Color(0xFF8061E8);
const Color lavender = Color(0xFFE9DFFF);
const Color blush = Color(0xFFF7DDF0);
const Color sky = Color(0xFFE1EAFF);
const Color cream = Color(0xFFFFFBF8);
const Color muted = Color(0xFF8177A8);
const Color mint = Color(0xFFE1F5E9);

class UnaryApp extends StatelessWidget {
  const UnaryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Unary Mathematical Processor',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF7F2FF),
        colorScheme: ColorScheme.fromSeed(
          seedColor: violet,
          primary: violet,
          surface: cream,
        ),
        fontFamily: 'Arial',
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.88),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          labelStyle: const TextStyle(color: muted),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFDCD1F5)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFDCD1F5)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: violet, width: 1.8),
          ),
        ),
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
  String currentPage = 'Simulator';
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

  @override
  void dispose() {
    timer?.cancel();
    mController.dispose();
    nController.dispose();
    super.dispose();
  }

  void initializeMachine() {
    final m = int.tryParse(mController.text.trim());
    final n = int.tryParse(nController.text.trim());

    if (m == null || n == null || m < 1 || n < 1 || m > 100 || n > 100) {
      setState(() => status = 'Enter whole numbers from 1 to 100.');
      return;
    }

    timer?.cancel();
    if (operation == 'Addition') {
      initializeAddition(m, n);
    } else {
      initializeMultiplication(m, n);
    }
  }

  void initializeAddition(int m, int n) {
    setState(() {
      mValue = m;
      nValue = n;
      tape = [...List.filled(m, '1'), 'B', ...List.filled(n, '1'), 'B'];
      head = 0;
      state = 'q0';
      steps = 0;
      completed = false;
      running = false;
      currentTransition = 'No transition yet.';
      status = 'Addition machine initialized.';
    });
  }

  void initializeMultiplication(int m, int n) {
    setState(() {
      mValue = m;
      nValue = n;
      tape = [...List.filled(m, '1'), 'B', ...List.filled(n, '1'), 'B'];
      head = 0;
      state = 'qM0';
      steps = 0;
      completed = false;
      running = false;
      currentTransition = 'No transition yet.';
      status = 'Multiplication simulation initialized.';
    });
  }

  void stepMachine() {
    if (tape.isEmpty || completed || running) return;
    if (operation == 'Addition') {
      stepAddition();
    } else {
      stepMultiplication();
    }
  }

  void stepAddition() {
    setState(() {
      if (head < 0 || head >= tape.length) {
        completed = true;
        state = 'q_accept';
        status = 'Addition computation complete.';
        running = false;
        timer?.cancel();
        return;
      }

      steps++;
      if (state == 'q0') {
        if (tape[head] == '1') {
          currentTransition = 'δ(q0, 1) → (q0, 1, R)';
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
          head++;
        } else if (tape[head] == 'B') {
          currentTransition = 'δ(q1, B) → (q_accept, B, S)';
          state = 'q_accept';
          completed = true;
          running = false;
          timer?.cancel();
          status = 'Addition computation complete.';
        }
      }
      if (!completed) status = 'Machine is running...';
    });
  }

  void stepMultiplication() {
    setState(() {
      steps++;
      if (state == 'qM0') {
        currentTransition = 'δ(qM0, 1) → (qM0, 1, R)';
        if (head < tape.length - 1) head++;
        if (head < tape.length && tape[head] == 'B') state = 'qM1';
      } else if (state == 'qM1') {
        currentTransition = 'δ(qM1, B) → (qM2, B, R)';
        if (head < tape.length - 1) head++;
        state = 'qM2';
      } else if (state == 'qM2') {
        if (head < tape.length && tape[head] == '1') {
          currentTransition = 'δ(qM2, 1) → (qM3, 1, R)';
          head++;
          state = 'qM3';
        } else {
          currentTransition = 'δ(qM2, B) → (q_accept, B, S)';
          state = 'q_accept';
          completed = true;
          running = false;
          timer?.cancel();
          status = 'Multiplication simulation complete.';
        }
      } else if (state == 'qM3') {
        currentTransition = 'δ(qM3, 1) → (qM4, 1, R)';
        final result = (mValue ?? 0) * (nValue ?? 0);
        tape = [...List.filled(result, '1'), 'B'];
        head = result;
        state = 'qM4';
      } else if (state == 'qM4') {
        currentTransition = 'δ(qM4, B) → (q_accept, B, S)';
        state = 'q_accept';
        completed = true;
        running = false;
        timer?.cancel();
        status = 'Multiplication simulation complete.';
      }
    });
  }

  void runMachine() {
    if (tape.isEmpty || completed || running) return;
    setState(() {
      running = true;
      status = 'Machine is running...';
    });
    timer?.cancel();
    timer = Timer.periodic(const Duration(milliseconds: 500), (t) {
      if (!mounted || completed || tape.isEmpty) {
        t.cancel();
        if (mounted) setState(() => running = false);
        return;
      }
      if (operation == 'Addition') {
        stepAddition();
      } else {
        stepMultiplication();
      }
      if (completed) t.cancel();
    });
  }

  void pauseMachine() {
    timer?.cancel();
    setState(() {
      running = false;
      if (!completed && tape.isNotEmpty) status = 'Execution paused.';
    });
  }

  void resetMachine() {
    timer?.cancel();
    setState(() {
      tape = [];
      head = 0;
      steps = 0;
      state = operation == 'Addition' ? 'q0' : 'qM0';
      completed = false;
      running = false;
      status = 'Enter M and N to begin.';
      currentTransition = 'No transition yet.';
    });
  }

  String get unaryResult => tape.where((symbol) => symbol == '1').join();
  int get decimalResult => unaryResult.length;

  List<List<String>> get transitionRows {
    if (operation == 'Addition') {
      return const [
        ['q0', '1', '1', 'R', 'q0'],
        ['q0', 'B', '1', 'R', 'q1'],
        ['q1', '1', '1', 'R', 'q1'],
        ['q1', 'B', 'B', 'S', 'q_accept'],
      ];
    }
    return const [
      ['qM0', '1', '1', 'R', 'qM0'],
      ['qM0', 'B', 'B', 'R', 'qM1'],
      ['qM1', 'B', 'B', 'R', 'qM2'],
      ['qM2', '1', '1', 'R', 'qM3'],
      ['qM3', '1', '1', 'R', 'qM4'],
      ['qM4', 'B', 'B', 'S', 'q_accept'],
    ];
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 900;
        return Scaffold(
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFFDF7FF), Color(0xFFF0E8FF), Color(0xFFFFF4F7)],
              ),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  if (wide) _sidebar(),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.all(wide ? 26 : 16),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1500),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _header(wide),
                              const SizedBox(height: 22),
                              if (!wide)
                                Wrap(
                                  spacing: 10,
                                  runSpacing: 10,
                                  children: [
                                    for (final page in ['Simulator', 'Theory', 'About'])
                                      ChoiceChip(
                                        label: Text(page),
                                        selected: currentPage == page,
                                        onSelected: (_) => setState(() => currentPage = page),
                                      ),
                                  ],
                                ),
                              const SizedBox(height: 16),
                              if (currentPage == 'Simulator') ...[
                              if (wide)
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(flex: 5, child: _inputCard()),
                                    const SizedBox(width: 16),
                                    Expanded(flex: 5, child: _operationCard()),
                                    const SizedBox(width: 16),
                                    Expanded(flex: 3, child: _actionCard()),
                                  ],
                                )
                              else ...[
                                _inputCard(),
                                const SizedBox(height: 14),
                                _operationCard(),
                                const SizedBox(height: 14),
                                _actionCard(),
                              ],
                              const SizedBox(height: 16),
                              _tapeCard(),
                              const SizedBox(height: 16),
                              _controlAndStatus(wide),
                              const SizedBox(height: 16),
                              if (wide)
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(flex: 5, child: _transitionCard()),
                                    const SizedBox(width: 16),
                                    Expanded(flex: 4, child: _resultCard()),
                                    const SizedBox(width: 16),
                                    Expanded(flex: 5, child: _tableCard()),
                                  ],
                                )
                              else ...[
                                _transitionCard(),
                                const SizedBox(height: 14),
                                _resultCard(),
                                const SizedBox(height: 14),
                                _tableCard(),
                              ],
                              const SizedBox(height: 24),
                              const Center(
                                child: Text(
                                  'Built with Flutter  •  Turing Theory into Interaction',
                                  style: TextStyle(color: muted, fontSize: 12),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              ] else if (currentPage == 'Theory') ...[
                                _theoryPage(),
                              ] else ...[
                                _aboutPage(),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _sidebar() => Container(
        width: 190,
        padding: const EdgeInsets.fromLTRB(16, 28, 16, 18),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF6D55C9), Color(0xFF9276E9), Color(0xFFB9A5F3)],
          ),
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(28),
            bottomRight: Radius.circular(28),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.psychology_alt_rounded, size: 42, color: Colors.white),
            const SizedBox(height: 8),
            const Text('Unary TM', style: TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.w800)),
            const SizedBox(height: 32),
            _sideItem(Icons.home_rounded, 'Simulator', true),
            _sideItem(Icons.menu_book_rounded, 'Theory', false),
            _sideItem(Icons.info_outline_rounded, 'About', false),
            const Spacer(),
            const Text('Turning theory\ninto interaction ✦', style: TextStyle(color: Colors.white, height: 1.5, fontSize: 14)),
          ],
        ),
      );

  Widget _sideItem(IconData icon, String label, bool selected) => InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => setState(() => currentPage = label),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          decoration: BoxDecoration(
            color: currentPage == label
                ? Colors.white.withValues(alpha: 0.22)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            border: currentPage == label
                ? Border.all(color: Colors.white.withValues(alpha: 0.25))
                : null,
          ),
          child: Row(children: [
            Icon(icon, color: Colors.white, size: 19),
            const SizedBox(width: 10),
            Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          ]),
        ),
      );

  Widget _header(bool wide) => Container(
        padding: EdgeInsets.symmetric(horizontal: wide ? 8 : 2, vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFFA88AF4), Color(0xFF7658D7)]),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [BoxShadow(color: violet.withValues(alpha: 0.22), blurRadius: 18, offset: const Offset(0, 7))],
              ),
              child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Unary Mathematical Processor',
                    style: TextStyle(
                      color: ink,
                      fontSize: wide ? 30 : 23,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.8,
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'A Turing Machine arithmetic simulator',
                    style: TextStyle(color: muted, fontSize: 14),
                  ),
                  if (wide) const Text('Explore unary arithmetic, visualize the tape, and follow every transition.', style: TextStyle(color: muted, fontSize: 13)),
                ],
              ),
            ),
            if (wide)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.75), borderRadius: BorderRadius.circular(30), border: Border.all(color: lavender)),
                child: const Row(children: [
                  Icon(Icons.auto_awesome, color: violet, size: 18),
                  SizedBox(width: 8),
                  Text('Explore  •  Visualize  •  Learn', style: TextStyle(color: ink, fontWeight: FontWeight.w600)),
                ]),
              ),
          ],
        ),
      );

  Widget _panel({required String title, required String subtitle, required IconData icon, required Widget child, Color? iconColor}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE8DDF8)),
        boxShadow: [BoxShadow(color: const Color(0xFF9274C9).withValues(alpha: 0.07), blurRadius: 22, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: (iconColor ?? violet).withValues(alpha: 0.13), borderRadius: BorderRadius.circular(14)),
              child: Icon(icon, color: iconColor ?? violet, size: 22),
            ),
            const SizedBox(width: 11),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(color: ink, fontSize: 17, fontWeight: FontWeight.w800)),
              if (subtitle.isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(subtitle, style: const TextStyle(color: muted, fontSize: 12)),
              ],
            ])),
          ]),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }

  Widget _inputCard() => _panel(
        title: 'Input numbers',
        subtitle: 'Enter two positive integers',
        icon: Icons.edit_note_rounded,
        child: LayoutBuilder(builder: (context, c) {
          final sideBySide = c.maxWidth > 360;
          final first = TextField(
            controller: mController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'M · First number', prefixIcon: Icon(Icons.looks_one_rounded, color: violet)),
          );
          final second = TextField(
            controller: nController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'N · Second number', prefixIcon: Icon(Icons.looks_two_rounded, color: violet)),
          );
          if (sideBySide) {
            return Row(children: [Expanded(child: first), const SizedBox(width: 12), Expanded(child: second)]);
          }
          return Column(children: [first, const SizedBox(height: 12), second]);
        }),
      );

  Widget _operationCard() => _panel(
        title: 'Select operation',
        subtitle: 'Choose what the machine should compute',
        icon: Icons.settings_suggest_rounded,
        child: Row(
          children: [
            Expanded(child: _operationOption('Addition', '+', 'M + N', Icons.add_rounded, violet)),
            const SizedBox(width: 12),
            Expanded(child: _operationOption('Multiplication', '×', 'M × N', Icons.close_rounded, const Color(0xFF9C79C9))),
          ],
        ),
      );

  Widget _operationOption(String value, String symbol, String caption, IconData icon, Color color) {
    final selected = operation == value;
    return InkWell(
      borderRadius: BorderRadius.circular(19),
      onTap: () {
        timer?.cancel();
        setState(() {
          operation = value;
          running = false;
          tape = [];
          head = 0;
          steps = 0;
          state = operation == 'Addition' ? 'q0' : 'qM0';
          completed = false;
          status = 'Select inputs and initialize the machine.';
          currentTransition = 'No transition yet.';
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 8),
        decoration: BoxDecoration(
          gradient: selected ? const LinearGradient(colors: [Color(0xFFF0E8FF), Color(0xFFFFEFF8)]) : null,
          color: selected ? null : const Color(0xFFFCFAFF),
          borderRadius: BorderRadius.circular(19),
          border: Border.all(color: selected ? color : const Color(0xFFE5DCF6), width: selected ? 1.7 : 1),
        ),
        child: Column(children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.13), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 25),
          ),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(color: ink, fontWeight: FontWeight.w800, fontSize: 14)),
          const SizedBox(height: 3),
          Text(caption, style: const TextStyle(color: muted, fontSize: 12)),
          const SizedBox(height: 5),
          Icon(selected ? Icons.check_circle_rounded : Icons.circle_outlined, size: 17, color: selected ? color : const Color(0xFFD6CBEA)),
        ]),
      ),
    );
  }

  Widget _actionCard() => _panel(
        title: 'Machine setup',
        subtitle: 'Prepare the virtual tape',
        icon: Icons.bolt_rounded,
        child: Column(children: [
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: initializeMachine,
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Padding(padding: EdgeInsets.symmetric(vertical: 13), child: Text('Initialize machine')),
              style: FilledButton.styleFrom(backgroundColor: violet, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: resetMachine,
              icon: const Icon(Icons.restart_alt_rounded),
              label: const Text('Reset'),
              style: OutlinedButton.styleFrom(foregroundColor: ink, side: const BorderSide(color: lavender), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
            ),
          ),
        ]),
      );

  Widget _tapeCard() => _panel(
        title: 'Turing machine tape',
        subtitle: 'Each cell stores one symbol; the arrow marks the current head',
        icon: Icons.view_week_rounded,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (mValue != null && nValue != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Wrap(spacing: 8, runSpacing: 6, children: [
                  _chip('M = $mValue', lavender, ink),
                  _chip('N = $nValue', blush, ink),
                  _chip(operation, sky, ink),
                ]),
              ),
            if (tape.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 12),
                decoration: BoxDecoration(color: const Color(0xFFFCFAFF), borderRadius: BorderRadius.circular(17), border: Border.all(color: const Color(0xFFE7DDF7))),
                child: const Column(children: [
                  Icon(Icons.view_week_outlined, size: 32, color: Color(0xFFB7A8DA)),
                  SizedBox(height: 8),
                  Text('Your tape is waiting', style: TextStyle(color: ink, fontWeight: FontWeight.w700)),
                  SizedBox(height: 4),
                  Text('Enter M and N, then initialize the machine.', style: TextStyle(color: muted, fontSize: 12), textAlign: TextAlign.center),
                ]),
              )
            else
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(padding: EdgeInsets.only(top: 40, right: 8), child: Text('…', style: TextStyle(color: muted, fontSize: 20))),
                    ...List.generate(tape.length, (index) {
                      final isHead = index == head;
                      final symbol = tape[index];
                      final isBlank = symbol == 'B';
                      return Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: Column(children: [
                          SizedBox(
                            height: 25,
                            child: isHead ? const Icon(Icons.arrow_drop_down_rounded, size: 31, color: Color(0xFFD44DA8)) : null,
                          ),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            width: 43,
                            height: 48,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              gradient: isHead
                                  ? const LinearGradient(colors: [Color(0xFFF7C9EC), Color(0xFFE9D7FF)])
                                  : isBlank
                                      ? const LinearGradient(colors: [Color(0xFFFFF7F1), Color(0xFFF7F0F7)])
                                      : const LinearGradient(colors: [Color(0xFFE7E7FF), Color(0xFFDDEBFF)]),
                              borderRadius: BorderRadius.circular(13),
                              border: Border.all(color: isHead ? const Color(0xFFD65EB4) : isBlank ? const Color(0xFFE9DDEB) : const Color(0xFFCFC7F4), width: isHead ? 2 : 1),
                              boxShadow: isHead ? [BoxShadow(color: blush.withValues(alpha: 0.8), blurRadius: 10)] : null,
                            ),
                            child: Text(symbol, style: TextStyle(color: isBlank ? const Color(0xFF9C8CA8) : ink, fontSize: 20, fontWeight: FontWeight.w800)),
                          ),
                          const SizedBox(height: 5),
                          if (isHead)
                            const Text('HEAD', style: TextStyle(color: Color(0xFFC34E9C), fontSize: 9, fontWeight: FontWeight.w900))
                          else
                            const SizedBox(height: 11),
                        ]),
                      );
                    }),
                    const Padding(padding: EdgeInsets.only(top: 40, left: 4), child: Text('…', style: TextStyle(color: muted, fontSize: 20))),
                  ],
                ),
              ),
            const SizedBox(height: 13),
            Wrap(spacing: 14, runSpacing: 8, children: [
              _legend(const Color(0xFFDDEBFF), '1 · Unary symbol'),
              _legend(const Color(0xFFFFF2EB), 'B · Blank symbol'),
              _legend(const Color(0xFFF3C9EB), 'Current head'),
            ]),
          ],
        ),
      );

  Widget _controlAndStatus(bool wide) {
    final controls = _panel(
      title: 'Execution controls',
      subtitle: 'Run one step at a time or automate the process',
      icon: Icons.gamepad_rounded,
      child: Wrap(
        spacing: 9,
        runSpacing: 9,
        children: [
          _controlButton('Step', Icons.skip_next_rounded, stepMachine, primary: true, disabled: tape.isEmpty || completed || running),
          _controlButton(running ? 'Running…' : 'Run', Icons.play_arrow_rounded, runMachine, disabled: tape.isEmpty || completed || running),
          _controlButton('Pause', Icons.pause_rounded, pauseMachine, disabled: !running),
          _controlButton('Reset', Icons.restart_alt_rounded, resetMachine),
        ],
      ),
    );
    final statusPanel = _panel(
      title: 'Machine status',
      subtitle: 'Live execution information',
      icon: Icons.monitor_heart_rounded,
      child: Column(children: [
        Row(children: [
          Expanded(child: _metric('Current state', state, Icons.settings_rounded, lavender)),
          const SizedBox(width: 8),
          Expanded(child: _metric('Steps', '$steps', Icons.numbers_rounded, sky)),
        ]),
        const SizedBox(height: 9),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: completed ? mint : const Color(0xFFF7F2FF), borderRadius: BorderRadius.circular(14)),
          child: Row(children: [
            Icon(completed ? Icons.check_circle_rounded : running ? Icons.sync_rounded : Icons.info_outline_rounded, color: completed ? const Color(0xFF258451) : violet),
            const SizedBox(width: 8),
            Expanded(child: Text(status, style: TextStyle(color: completed ? const Color(0xFF236D46) : ink, fontWeight: FontWeight.w600, fontSize: 12))),
          ]),
        ),
      ]),
    );
    if (wide) {
      return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(flex: 6, child: controls),
        const SizedBox(width: 16),
        Expanded(flex: 5, child: statusPanel),
      ]);
    }
    return Column(children: [controls, const SizedBox(height: 14), statusPanel]);
  }

  Widget _controlButton(String label, IconData icon, VoidCallback action, {bool primary = false, bool disabled = false}) {
    return FilledButton.tonalIcon(
      onPressed: disabled ? null : action,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: FilledButton.styleFrom(
        backgroundColor: primary ? violet : const Color(0xFFF0E9FF),
        foregroundColor: primary ? Colors.white : ink,
        disabledBackgroundColor: const Color(0xFFF5F1FA),
        disabledForegroundColor: const Color(0xFFB9B0C9),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
    );
  }

  Widget _transitionCard() => _panel(
        title: 'Current transition',
        subtitle: 'The rule being executed right now',
        icon: Icons.east_rounded,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFFF0E8FF), Color(0xFFFFEFF8)]),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE3D4FB)),
            ),
            child: SelectableText(currentTransition, textAlign: TextAlign.center, style: const TextStyle(fontFamily: 'monospace', color: ink, fontSize: 15, fontWeight: FontWeight.w800)),
          ),
          const SizedBox(height: 12),
          Wrap(spacing: 8, runSpacing: 8, children: [
            _chip('q0 · Current state', lavender, ink),
            _chip('1 · Write symbol', blush, ink),
            _chip('R · Move right', sky, ink),
            _chip('S · Stay', const Color(0xFFFFEAC9), ink),
          ]),
        ]),
      );

  Widget _resultCard() => _panel(
        title: 'Result',
        subtitle: 'Final output after the machine halts',
        icon: Icons.emoji_events_rounded,
        iconColor: const Color(0xFFD79A34),
        child: Column(children: [
          if (!completed)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 12),
              decoration: BoxDecoration(color: const Color(0xFFFCFAFF), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE8DDF8))),
              child: const Column(children: [
                Icon(Icons.hourglass_empty_rounded, color: Color(0xFFB5A5D8), size: 29),
                SizedBox(height: 8),
                Text('Result appears here', style: TextStyle(color: ink, fontWeight: FontWeight.w700)),
                SizedBox(height: 4),
                Text('Run the machine to completion.', style: TextStyle(color: muted, fontSize: 12)),
              ]),
            )
          else ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFFF0E5FF), Color(0xFFFFEAF6)]), borderRadius: BorderRadius.circular(17)),
              child: Column(children: [
                const Text('UNARY RESULT', style: TextStyle(color: muted, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
                const SizedBox(height: 8),
                SelectableText(unaryResult, textAlign: TextAlign.center, style: const TextStyle(color: ink, fontFamily: 'monospace', fontSize: 19, fontWeight: FontWeight.w800, letterSpacing: 2)),
              ]),
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: mint, borderRadius: BorderRadius.circular(16)),
              child: Column(children: [
                const Text('DECIMAL RESULT', style: TextStyle(color: Color(0xFF438461), fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
                const SizedBox(height: 4),
                Text('$decimalResult', style: const TextStyle(color: Color(0xFF236D46), fontSize: 30, fontWeight: FontWeight.w900)),
              ]),
            ),
            const SizedBox(height: 9),
            Row(children: const [
              Icon(Icons.check_circle_rounded, color: Color(0xFF258451), size: 18),
              SizedBox(width: 7),
              Expanded(child: Text('Machine halted successfully', style: TextStyle(color: Color(0xFF236D46), fontSize: 12, fontWeight: FontWeight.w700))),
            ]),
          ],
        ]),
      );

  Widget _tableCard() => _panel(
        title: 'Transition table',
        subtitle: 'Transition function δ',
        icon: Icons.table_chart_rounded,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(const Color(0xFFF0E8FF)),
            dataRowMinHeight: 40,
            dataRowMaxHeight: 48,
            horizontalMargin: 10,
            columnSpacing: 17,
            columns: const [
              DataColumn(label: Text('State')),
              DataColumn(label: Text('Read')),
              DataColumn(label: Text('Write')),
              DataColumn(label: Text('Move')),
              DataColumn(label: Text('Next')),
            ],
            rows: transitionRows.map((row) {
              return DataRow(
                cells: row.map((value) {
                  return DataCell(
                    Text(
                      value,
                      style: const TextStyle(
                        color: ink,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                }).toList(),
              );
            }).toList(),
          ),
        ),
      );

  Widget _metric(String label, String value, IconData icon, Color tint) => Container(
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(color: tint.withValues(alpha: 0.48), borderRadius: BorderRadius.circular(15)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, size: 18, color: violet),
          const SizedBox(height: 7),
          Text(label, style: const TextStyle(color: muted, fontSize: 10)),
          const SizedBox(height: 3),
          Text(value, style: const TextStyle(color: ink, fontWeight: FontWeight.w900, fontSize: 18)),
        ]),
      );

  Widget _chip(String text, Color color, Color textColor) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(30), border: Border.all(color: Colors.white.withValues(alpha: 0.9))),
        child: Text(text, style: TextStyle(color: textColor, fontSize: 11, fontWeight: FontWeight.w700)),
      );

  Widget _legend(Color color, String label) => Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 13, height: 13, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4), border: Border.all(color: const Color(0xFFD8CDEA)))),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(color: muted, fontSize: 11)),
      ]);

  Widget _theoryPage() => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _panel(
            title: 'What is a Turing Machine?',
            subtitle: 'The basic concept',
            icon: Icons.menu_book_rounded,
            child: const Text(
              'A Turing Machine is a mathematical model of computation. It uses a tape, a read/write head, a set of states, and transition rules to process input.',
              style: TextStyle(color: ink, height: 1.6),
            ),
          ),
          const SizedBox(height: 16),
          _panel(
            title: 'Unary Number System',
            subtitle: 'Representing numbers',
            icon: Icons.looks_one_rounded,
            child: const Text(
              'In unary representation, a number is represented using repeated 1s.\n\n1 = 1\n2 = 11\n3 = 111\n4 = 1111',
              style: TextStyle(color: ink, height: 1.6),
            ),
          ),
          const SizedBox(height: 16),
          _panel(
            title: 'Addition Example',
            subtitle: '3 + 2 = 5',
            icon: Icons.calculate_rounded,
            child: const Text(
              'Input: 111 B 11\nOutput: 11111\n\nB represents the separator/blank symbol. The addition simulation replaces the separator with 1, giving five unary symbols.',
              style: TextStyle(color: ink, height: 1.6, fontFamily: 'monospace'),
            ),
          ),
          const SizedBox(height: 16),
          _panel(
            title: 'Important Symbols',
            subtitle: 'Understanding the tape',
            icon: Icons.memory_rounded,
            child: const Text(
              '1 — Unary symbol\nB — Blank or separator symbol\nq0, q1, q_accept — Machine states\nR — Move the head right\nS — Stay in the current position',
              style: TextStyle(color: ink, height: 1.7),
            ),
          ),
        ],
      );

  Widget _aboutPage() => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _panel(
            title: 'About This Project',
            subtitle: 'Unary Mathematical Processor',
            icon: Icons.info_outline_rounded,
            child: const Text(
              'This project demonstrates unary arithmetic through a visual simulation inspired by Turing Machine concepts. It helps students understand how input symbols, states, and transitions work together.',
              style: TextStyle(color: ink, height: 1.6),
            ),
          ),
          const SizedBox(height: 16),
          _panel(
            title: 'Project Objectives',
            subtitle: 'What you can learn',
            icon: Icons.flag_rounded,
            child: const Text(
              '• Understand unary number representation.\n• Visualize tape symbols and head movement.\n• Explore step-by-step machine execution.\n• Observe arithmetic results in unary form.',
              style: TextStyle(color: ink, height: 1.7),
            ),
          ),
          const SizedBox(height: 16),
          _panel(
            title: 'Technology Stack',
            subtitle: 'Built with',
            icon: Icons.code_rounded,
            child: const Text(
              'Flutter — User interface\nDart — Application logic\nThe interface is designed for Windows and Android.',
              style: TextStyle(color: ink, height: 1.7),
            ),
          ),
          const SizedBox(height: 16),
          _panel(
            title: 'Project Scope',
            subtitle: 'A learning demonstration',
            icon: Icons.lightbulb_outline_rounded,
            child: const Text(
              'Addition and multiplication are available in the simulator. Multiplication is a simplified demonstration and is not a complete formal Turing Machine multiplication implementation.',
              style: TextStyle(color: ink, height: 1.6),
            ),
          ),
        ],
      );

}
