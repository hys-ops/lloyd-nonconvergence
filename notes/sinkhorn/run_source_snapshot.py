"""Run pinned POT Python sources with native extension imports supplied by a release wheel.

This fallback is for the CPU NumPy Sinkhorn comparison only. Both arms use the
same pinned pure-Python solver, NumPy backend and pinned benchmark fixture.
"""
import hashlib
import importlib.metadata
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile

import ot

HERE = Path(__file__).resolve().parent
REV = "367355d757223e39989e384b7a93d0537b1547ea"


def main():
    if len(sys.argv) < 3:
        raise SystemExit("Usage: python run_source_snapshot.py POT NEW_OUTPUT_DIR [--repeats N]")
    checkout, out = (Path(a).resolve() for a in sys.argv[1:3])
    if subprocess.check_output(["git", "-C", str(checkout), "rev-parse", "HEAD"], text=True).strip() != REV:
        raise SystemExit("Wrong upstream revision")
    dist = importlib.metadata.distribution("POT")
    if dist.version != "0.9.7":
        raise SystemExit("Install the POT 0.9.7 native wheel for the source-only fallback")
    wheel_ot = Path(ot.__file__).resolve().parent
    with tempfile.TemporaryDirectory() as directory:
        root = Path(directory)
        target = root / "ot"
        # Use tracked files from the commit even if the user's checkout is dirty.
        tree = subprocess.check_output(["git", "-C", str(checkout), "ls-tree", "-r",
                                        "--name-only", "-z", REV, "ot"])
        for rel in tree.decode().strip("\0").split("\0"):
            if not rel.endswith(".py"):
                continue
            dst = root / rel
            dst.parent.mkdir(parents=True, exist_ok=True)
            dst.write_bytes(subprocess.check_output(["git", "-C", str(checkout), "show", f"{REV}:{rel}"]))
        blobs = {}
        for lib in sorted(wheel_ot.rglob("*.so")):
            dest = target / lib.relative_to(wheel_ot)
            dest.parent.mkdir(parents=True, exist_ok=True)
            shutil.copyfile(lib, dest)
            blobs[str(dest.relative_to(root))] = hashlib.sha256(dest.read_bytes()).hexdigest()
        if not blobs:
            raise RuntimeError("No Linux wheel extensions found")
        native_libs = wheel_ot.parent / "pot.libs"
        if native_libs.is_dir():
            (root / "pot.libs").symlink_to(native_libs, target_is_directory=True)
        env = dict(os.environ)
        env["PYTHONPATH"] = os.pathsep.join([str(root), env.get("PYTHONPATH", "")])
        subprocess.run([sys.executable, str(HERE / "reproduce.py"), str(checkout), str(out),
                        *sys.argv[3:]], cwd=root, env=env, check=True)
        info = dict(source_revision=REV, imported_native_extensions_from=dist.version, sha256=blobs,
                    mode="Pinned Python sources plus release-wheel native modules for package import")
        (out / "source-mode.json").write_text(json.dumps(info, indent=2) + "\n")


if __name__ == "__main__":
    main()
