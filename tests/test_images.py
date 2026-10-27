"""Check image sizing in Typst without requiring a browser or network access."""

from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[1]


@unittest.skipUnless(shutil.which("quarto"), "Quarto is required for Typst layout tests")
class ImageSizingTests(unittest.TestCase):
    def test_images_fit_columns_and_nested_blocks(self):
        with tempfile.TemporaryDirectory(prefix="cheatsheet-images-") as directory:
            project = Path(directory)
            for name in ("typst-template.typ", "callouts.typ"):
                shutil.copy2(ROOT / "_extensions/cheatsheet" / name, project / name)
            (project / "wide.svg").write_text(
                '<svg xmlns="http://www.w3.org/2000/svg" width="1600" height="160">'
                '<rect width="1600" height="160" fill="blue"/></svg>'
            )
            source = r'''
#import "typst-template.typ": cheatsheet
#import "callouts.typ": tipp
#show: cheatsheet.with(cols: COLS)

#let check-width(expected) = layout(size => {
  assert(calc.abs(size.width - expected) < 0.01pt)

  // Quarto emits both width and height for rendered Mermaid images.
  let wide = measure(image("wide.svg", width: 12in, height: 1in), width: size.width)
  assert(calc.abs(wide.width - size.width) < 0.01pt, message: repr(wide))
  assert(calc.abs(wide.height / wide.width - 1 / 12) < 0.001)

  // Natural-size images are constrained too, without distorting their ratio.
  let natural = measure(image("wide.svg"), width: size.width)
  assert(calc.abs(natural.width - size.width) < 0.01pt, message: repr(natural))
  assert(calc.abs(natural.height / natural.width - 1 / 10) < 0.001)

  // Small images stay small, including when used inline in raw Typst.
  let small = measure(image("wide.svg", width: 12pt), width: size.width)
  assert(calc.abs(small.width - 12pt) < 0.01pt, message: repr(small))
  let inline-image = measure([Before #image("wide.svg", width: 12pt) after.], width: size.width)
  let inline-box = measure([Before #box(width: 12pt, height: 1.2pt) after.], width: size.width)
  assert(calc.abs(inline-image.height - inline-box.height) < 0.01pt)
})

#let column-width = (297mm - 20mm - (COLS - 1) * 9pt) / COLS
#check-width(column-width)
#block(width: 100%, inset: 8pt)[#check-width(column-width - 16pt)]
#tipp[#check-width(column-width - 16pt)]
'''
            for cols in (1, 2, 3, 4):
                with self.subTest(cols=cols):
                    (project / "check.typ").write_text(source.replace("COLS", str(cols)))
                    result = subprocess.run(
                        ["quarto", "typst", "compile", "check.typ", "check.pdf"],
                        cwd=project, capture_output=True, text=True,
                    )
                    self.assertEqual(result.returncode, 0, result.stdout + result.stderr)


if __name__ == "__main__":
    unittest.main()
