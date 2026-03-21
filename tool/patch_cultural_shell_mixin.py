import re
import pathlib

ROOT = pathlib.Path(__file__).resolve().parents[1] / "lib/screens/games/cultural"
APPBAR_BLOCK = re.compile(
    r"\n  @override\n  List<Widget>\? get appBarActions \{.*?\n  \}\n\n  @override\n  Widget buildGameContent",
    re.DOTALL,
)

for path in sorted(ROOT.glob("*.dart")):
    text = path.read_text(encoding="utf-8")
    if "RoundProgressGameShellMixin" in text:
        continue
    if "appBarActions" not in text:
        continue
    m = re.search(r"class (_\w+State) extends BaseGameScreenState<(\w+)>\s*\{", text)
    if not m:
        print("skip class pattern", path.name)
        continue
    state, game = m.group(1), m.group(2)
    if "import '../mixins/round_progress_shell_mixin.dart';" not in text:
        text = text.replace(
            "import '../base_game_screen.dart';\n",
            "import '../base_game_screen.dart';\nimport '../mixins/round_progress_shell_mixin.dart';\n",
            1,
        )
    text = text.replace(
        f"class {state} extends BaseGameScreenState<{game}> {{",
        f"class {state} extends BaseGameScreenState<{game}>\n    with RoundProgressGameShellMixin<{game}> {{",
        1,
    )
    ins = """
  @override
  int get gameRound => _round;

  @override
  int get gameMaxRounds => _maxRounds;

  @override
  int get gameScore => _score;
"""
    if "int get gameRound => _round" in text:
        print("already getters", path.name)
        continue
    m2 = re.search(r"(\n  final int _maxRounds = \d+;\n)", text)
    if not m2:
        print("skip maxRounds", path.name)
        continue
    text = text.replace(m2.group(1), m2.group(1) + ins, 1)
    new_text, n = APPBAR_BLOCK.subn(
        "\n  @override\n  Widget buildGameContent",
        text,
        count=1,
    )
    if n != 1:
        print("appBar block mismatch", path.name)
        continue
    path.write_text(new_text, encoding="utf-8")
    print("patched", path.name)
