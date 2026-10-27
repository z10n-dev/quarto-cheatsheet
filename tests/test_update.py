"""Offline integration tests for update.sh (standard-library dependencies only)."""

import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[1]


class UpdateTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.upstream_tmp = tempfile.TemporaryDirectory(prefix="cheatsheet-upstream-")
        cls.addClassCleanup(cls.upstream_tmp.cleanup)
        cls.upstream = Path(cls.upstream_tmp.name)
        for name in ("_extensions", "template"):
            shutil.copytree(ROOT / name, cls.upstream / name)
        for name in ("flake.nix", "flake.lock", "setup.sh", "update.sh"):
            shutil.copy2(ROOT / name, cls.upstream / name)
        # Exercise replacing the running script with a different-length version.
        with (cls.upstream / "update.sh").open("a") as script:
            script.write("\n# New upstream version\n")
        cls.git("init", "--quiet", "-b", "main")
        cls.git("add", ".")
        cls.git("-c", "user.name=Test", "-c", "user.email=test@example.org",
                "-c", "commit.gpgsign=false", "commit", "--quiet", "-m", "Fixture")
        cls.git("tag", "test-release")
        cls.git("checkout", "--quiet", "-b", "incomplete-template")
        cls.git("rm", "--quiet", "flake.nix")
        cls.git("-c", "user.name=Test", "-c", "user.email=test@example.org",
                "-c", "commit.gpgsign=false", "commit", "--quiet", "-m", "Incomplete fixture")
        cls.git("checkout", "--quiet", "main")

    @classmethod
    def git(cls, *args):
        subprocess.run(["git", "-C", str(cls.upstream), *args], check=True,
                       capture_output=True, text=True)

    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory(prefix="cheatsheet-project-")
        self.addCleanup(self.tmp.cleanup)
        self.project = Path(self.tmp.name)
        self.write("index.qmd", "# My own notes\n")
        self.write("_quarto.yml", "project:\n  type: default\n")
        self.write("flake.nix", "custom flake\n")
        self.write("flake.lock", "custom lock\n")
        self.write("_extensions/cheatsheet/custom.typ", "custom extension\n")
        self.write("template/custom.txt", "custom template\n")
        self.write(".envrc", "# Custom direnv configuration\n")
        self.write(".gitignore", "custom-ignore\n")
        shutil.copy2(ROOT / "update.sh", self.project / "update.sh")
        self.env = dict(os.environ, CHEATSHEET_REPOSITORY=self.upstream.as_uri())

    def write(self, name, content):
        path = self.project / name
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(content)

    def run_update(self, *args, input_text=None):
        return subprocess.run(
            ["bash", str(self.project / "update.sh"), *args],
            cwd=self.project, env=self.env, input=input_text,
            capture_output=True, text=True,
        )

    def backup(self):
        backups = list((self.project / ".cheatsheet-backups").iterdir())
        self.assertEqual(len(backups), 1)
        return backups[0]

    def test_update_backs_up_customizations_and_preserves_documents(self):
        self.write(".gitea/workflows/render.yml", "custom workflow\n")
        result = self.run_update("gitea", "--yes")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("Update complete", result.stdout)
        self.assertEqual((self.project / "index.qmd").read_text(), "# My own notes\n")
        self.assertEqual((self.project / ".envrc").read_text(),
                         "# Custom direnv configuration\n")
        self.assertEqual((self.project / ".gitignore").read_text(),
                         "custom-ignore\n\n/.cheatsheet-backups/\n")
        self.assertEqual((self.project / "_quarto.yml").read_text(),
                         "project:\n  type: default\n")
        backup = self.backup()
        for name, content in (
            ("flake.nix", "custom flake\n"),
            ("flake.lock", "custom lock\n"),
            ("_extensions/cheatsheet/custom.typ", "custom extension\n"),
            ("template/custom.txt", "custom template\n"),
            (".gitea/workflows/render.yml", "custom workflow\n"),
            (".gitignore", "custom-ignore\n"),
        ):
            self.assertEqual((backup / name).read_text(), content)
        for name in ("flake.nix", "flake.lock", "setup.sh", "update.sh",
                     "_extensions/cheatsheet/_extension.yml"):
            self.assertEqual((self.project / name).read_bytes(),
                             (self.upstream / name).read_bytes())
        self.assertFalse((self.project / "_extensions/cheatsheet/custom.typ").exists())
        self.assertTrue(os.access(self.project / "update.sh", os.X_OK))

    def test_each_platform_installs_the_correct_workflow(self):
        for platform, target in (
            ("github", ".github/workflows/render.yml"),
            ("gitlab", ".gitlab-ci.yml"),
            ("gitea", ".gitea/workflows/render.yml"),
        ):
            with self.subTest(platform=platform):
                result = self.run_update(platform, "--yes")
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertEqual((self.project / target).read_bytes(),
                                 (self.upstream / f"template/workflows/{platform}.yml").read_bytes())

    def test_detects_existing_platform(self):
        self.write(".gitea/workflows/render.yml", "old workflow\n")
        result = self.run_update("--yes")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("Detected CI platform: gitea", result.stdout)

    def test_none_keeps_existing_workflow(self):
        self.write(".gitea/workflows/render.yml", "custom workflow\n")
        result = self.run_update("none", "--yes")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual((self.project / ".gitea/workflows/render.yml").read_text(),
                         "custom workflow\n")

    def test_declining_does_not_change_files(self):
        result = self.run_update("gitea", input_text="n\n")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("cancelled", result.stdout)
        self.assertEqual((self.project / "flake.nix").read_text(), "custom flake\n")
        self.assertFalse((self.project / ".cheatsheet-backups").exists())

    def test_missing_ref_does_not_change_files(self):
        result = self.run_update("gitea", "--yes", "--ref", "missing-branch")
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual((self.project / "flake.nix").read_text(), "custom flake\n")
        self.assertFalse((self.project / ".cheatsheet-backups").exists())

    def test_can_update_from_a_tag(self):
        result = self.run_update("none", "--yes", "--ref", "test-release")
        self.assertEqual(result.returncode, 0, result.stderr)

    def test_incomplete_snapshot_does_not_change_files(self):
        result = self.run_update("gitea", "--yes", "--ref", "incomplete-template")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("Template is missing flake.nix", result.stderr)
        self.assertEqual((self.project / "flake.nix").read_text(), "custom flake\n")
        self.assertFalse((self.project / ".cheatsheet-backups").exists())

    def test_interactive_platform_selection(self):
        result = self.run_update(input_text="3\ny\n")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertTrue((self.project / ".gitea/workflows/render.yml").is_file())

    def test_repeated_updates_keep_separate_backups_and_one_ignore_entry(self):
        for _ in range(2):
            result = self.run_update("none", "--yes")
            self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(len(list((self.project / ".cheatsheet-backups").iterdir())), 2)
        self.assertEqual((self.project / ".gitignore").read_text().count(
            "/.cheatsheet-backups/"), 1)

    def test_creates_missing_dotfiles(self):
        (self.project / ".envrc").unlink()
        (self.project / ".gitignore").unlink()
        result = self.run_update("none", "--yes")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual((self.project / ".envrc").read_bytes(),
                         (self.upstream / "template/envrc").read_bytes())

    def test_ambiguous_platform_requires_explicit_selection_with_yes(self):
        self.write(".gitea/workflows/render.yml", "gitea\n")
        self.write(".github/workflows/render.yml", "github\n")
        result = self.run_update("--yes")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("ambiguous", result.stderr)
        self.assertFalse((self.project / ".cheatsheet-backups").exists())

    def test_invalid_arguments_do_not_change_files(self):
        for args in (("--ref",), ("unknown",), ("github", "gitea")):
            with self.subTest(args=args):
                result = self.run_update(*args)
                self.assertNotEqual(result.returncode, 0)
        self.assertFalse((self.project / ".cheatsheet-backups").exists())


if __name__ == "__main__":
    unittest.main()
