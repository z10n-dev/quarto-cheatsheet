"""Test percentage-width Mermaid cells without running a browser."""

from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[1]


@unittest.skipUnless(shutil.which("quarto"), "Quarto is required for Pandoc filter tests")
class MermaidWidthTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory(prefix="cheatsheet-mermaid-width-")
        self.addCleanup(self.tmp.cleanup)
        self.project = Path(self.tmp.name)
        for name in ("blocks-filter.lua", "math-macros.lua"):
            shutil.copy2(ROOT / "_extensions/cheatsheet" / name, self.project / name)

    def convert(self, content):
        return subprocess.run(
            ["quarto", "pandoc", "--from", "markdown", "--to", "typst",
             "--lua-filter", "blocks-filter.lua"],
            cwd=self.project, input=content, capture_output=True, text=True,
        )

    def cell(self, width=None, image="mermaid-figure-1.png"):
        attribute = f' width="{width}"' if width is not None else ""
        return f'''::: {{.cell{attribute}}}
::: {{.cell-output-display}}
![Example caption]({image}){{#fig-example width=12in height=1in}}
:::
:::
'''

    def test_percentage_wraps_mermaid_and_preserves_caption_and_label(self):
        for width in ("70%", "42.5%", "100%"):
            with self.subTest(width=width):
                result = self.convert(self.cell(width))
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertIn(f"#block(width: {width})[", result.stdout)
                self.assertIn("Example caption", result.stdout)
                self.assertIn("<fig-example>", result.stdout)
                self.assertIn('image("mermaid-figure-1.png"', result.stdout)

    def test_works_with_svg_and_inside_callouts(self):
        content = "::: tipp\n" + self.cell("70%", "figures/mermaid-figure-2.svg") + ":::\n"
        result = self.convert(content)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("#tipp()", result.stdout)
        self.assertIn("#block(width: 70%)[", result.stdout)

    def test_rejects_invalid_percentage_values(self):
        for width in ("0%", "101%", "-5%", "70", "2in", "anything"):
            with self.subTest(width=width):
                result = self.convert(self.cell(width))
                self.assertNotEqual(result.returncode, 0)
                self.assertIn("Mermaid width must be a percentage", result.stderr)

    def test_does_not_change_default_mermaid_size(self):
        result = self.convert(self.cell())
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertNotIn("#block(width:", result.stdout)

    def test_does_not_change_other_images_or_non_cell_divs(self):
        for content in (
            self.cell("70%", "ordinary-image.png"),
            '::: {width="70%"}\n![](mermaid-figure-1.png)\n:::\n',
        ):
            with self.subTest(content=content):
                result = self.convert(content)
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertNotIn("#block(width:", result.stdout)


if __name__ == "__main__":
    unittest.main()
