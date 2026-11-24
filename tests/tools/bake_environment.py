"""Rebuild all three maps. WARNING: replaces manual room scenery edits."""
import runpy
from pathlib import Path
if __name__ == "__main__":
    runpy.run_path(str(Path(__file__).with_name("finish_art_migration.py")), run_name="__main__")
