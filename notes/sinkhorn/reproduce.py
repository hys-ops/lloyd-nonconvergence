"""Compare a local post-row stopping prototype with the pinned upstream function.

Requires an installed build of the commit listed in README.md and a clean
checkout of the same commit. The patch is applied to a temporary copy only.
"""
import argparse
import csv

import importlib.util
import inspect
import json

import platform
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path
from statistics import median
from time import perf_counter_ns

import numpy as np
import ot
import scipy
from threadpoolctl import threadpool_info, threadpool_limits

HERE = Path(__file__).resolve().parent
REV = "367355d757223e39989e384b7a93d0537b1547ea"
BLOB = "152112364cedae38c02076e17d78e8aab9693a5b"
REL = Path("ot/bregman/_sinkhorn.py")
STOCK = ot.bregman.sinkhorn_knopp
CHECKS = (0, 4, 7, 9)
OPTIONS = {
    "stock": None,
    "count-extra": ("count", CHECKS),
    "geometry-cadence10": ("geometry", (0,)),
    "geometry-extra": ("geometry", CHECKS),
}


def git(checkout, *args):
    return subprocess.check_output(["git", "-C", str(checkout), *args], text=True).strip()


def load_prototype(checkout, directory):
    if git(checkout, "rev-parse", "HEAD") != REV or git(checkout, "hash-object", str(REL)) != BLOB:
        raise ValueError("Checkout does not match the reviewed revision")
    stock_file = Path(inspect.getfile(STOCK))
    if stock_file.read_bytes() != (checkout / REL).read_bytes():
        raise ValueError("Installed solver and checkout differ. Install the pinned checkout.")
    tmp_file = directory / REL
    tmp_file.parent.mkdir(parents=True)
    shutil.copyfile(stock_file, tmp_file)
    subprocess.run(["git", "apply", str(HERE / "postrow-review.patch")], cwd=directory, check=True)
    spec = importlib.util.spec_from_file_location("ot.bregman._local_plan_tv_review", tmp_file)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod.sinkhorn_knopp


def fixtures(setup):
    for n in (50, 500):
        a, b, M = setup(n)
        yield f"upstream-{n}", (a, b, M, 1.0), None
    # A nonuniform, planted Gibbs scaling. Both temperatures use the same
    # locations and scaling vectors. Reference entropy optimality follows
    # from positivity, the two margins, and the diagonal-scaling identity.
    x = np.linspace(0, 1, 64)
    y = np.linspace(0, 1, 128)
    M = (x[:, None] - y[None, :]) ** 2 / 2
    for reg in (0.25, 0.02):
        P = np.exp(-M / reg) * (0.2 + x[:, None]) * (1.3 - y[None, :])
        P /= P.sum()
        yield f"planted-{reg}", (P.sum(axis=1), P.sum(axis=0), M, reg), P


def run(checkout, out, repeats):
    if repeats < 1:
        raise ValueError("repeats must be positive")
    out.mkdir(exist_ok=False, parents=True)
    sys.path.append(str(checkout))
    from benchmarks import sinkhorn_knopp as bench
    if Path(bench.__file__).resolve() != checkout / "benchmarks/sinkhorn_knopp.py":
        raise ValueError("Wrong upstream benchmark import")
    rng = np.random.default_rng(47813)
    detail, summary = [], []
    with tempfile.TemporaryDirectory() as tmp, threadpool_limits(limits=1):
        local = load_prototype(checkout, Path(tmp))
        metadata = dict(commit=REV, pot=ot.__version__, python=platform.python_version(),
                        numpy=np.__version__, scipy=scipy.__version__, platform=platform.platform(),
                        cpu=platform.processor(), blas=threadpool_info(), repeats=repeats,
                        seed=47813, marginal_tolerance=1e-7, plan_tv_tolerance=2.5e-8)
        for label, args, planted in fixtures(bench.setup):
            ref = planted if planted is not None else STOCK(*args, numItermax=10000, stopThr=1e-14)
            a, b, M, reg = args

            def solve(name, log=False):
                common = dict(stopThr=1e-7, numItermax=1000, log=log)
                if name == "stock":
                    return STOCK(*args, **common)
                factor, probes = OPTIONS[name]
                return local(*args, **common, plan_tv_tol=2.5e-8,
                             _review_factor=factor, _review_probes=probes)

            if not np.array_equal(local(*args, stopThr=1e-7), solve("stock")):
                raise AssertionError("Default changed on this input")
            observed = {}
            for name in OPTIONS:
                P, log = solve(name, log=True)
                plain = solve(name)
                np.testing.assert_array_equal(plain, P)
                if not np.isfinite(P).all() or (P < 0).any():
                    raise AssertionError("Nonfinite or negative result")
                tv = 0.5 * np.abs(P - ref).sum()
                l2a, l2b = np.linalg.norm(P.sum(axis=1) - a), np.linalg.norm(P.sum(axis=0) - b)
                est = log.get("plan_tv_estimate")
                if est is not None:
                    if not (est < 2.5e-8 and max(l2a,l2b) < 1e-7):
                        raise AssertionError("Returned without meeting thresholds")
                    if tv > est + 2e-12:
                        raise AssertionError("Float64 reference disagrees beyond comparison slack")
                observed[name] = dict(case=label, mode=name, iterations=log["niter"] + 1,
                                      estimated_tv=est, tv_to_reference=tv, row_l2=l2a, col_l2=l2b)
            # Warmups and diagnostic logging are above, outside timing. Input
            # generation/reference solve are excluded. K and dense output are timed.
            times = {name: [] for name in OPTIONS}
            for rep in range(repeats):
                for name in rng.permutation(list(OPTIONS)):
                    t0 = perf_counter_ns()
                    P = solve(name)
                    ms = (perf_counter_ns() - t0) / 1e6
                    del P
                    times[name].append(ms)
                    detail.append(dict(case=label, repeat=rep+1, mode=name, ms=ms))
            for name, row in observed.items():
                row.update(ms_median=median(times[name]), ms_q25=np.quantile(times[name], 0.25),
                           ms_q75=np.quantile(times[name], 0.75))
                summary.append(row)
        # Failure behavior of review mode, tested on a nonconverged iterate.
        try:
            local(*args, numItermax=1, plan_tv_tol=1e-15, warn=False)
        except RuntimeError:
            pass
        else:
            raise AssertionError("Exhausted run reported a plan")
        zero = a.copy()
        zero[0] = 0
        try:
            local(zero, b, M, reg, plan_tv_tol=1e-6)
        except ValueError:
            pass
        else:
            raise AssertionError("Zero weights accepted")
    for fname, data in (("trials.csv", detail), ("summary.csv", summary)):
        with (out / fname).open("w", newline="") as f:
            writer = csv.DictWriter(f, list(data[0]))
            writer.writeheader()
            writer.writerows(data)
    (out / "environment.json").write_text(json.dumps(metadata, indent=2, default=str) + "\n")
    print((out / "summary.csv").read_text(), end="")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("checkout", type=Path)
    parser.add_argument("new_output_dir", type=Path)
    parser.add_argument("--repeats", type=int, default=31)
    opts = parser.parse_args()
    run(opts.checkout.resolve(), opts.new_output_dir, opts.repeats)
