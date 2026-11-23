"""Independent 2x2 oracle for a candidate dense plan. Run --help for usage."""
import argparse
from decimal import Decimal as D, getcontext

getcontext().prec = 80

def reference(a, b, kernel):
    """a, b: first row/column masses; kernel: four positive entries, row-major."""
    k11, k12, k21, k22 = kernel
    low, high = max(D(0), a + b - 1), min(a, b)
    ratio = k11 * k22 / (k12 * k21)
    # For every feasible interior t, odds are strictly increasing in t.
    # Compare by cross-multiplication to avoid singular endpoint ratios.
    for _ in range(230):
        t = (low + high) / 2
        first = t * (1 - a - b + t)
        second = ratio * (a - t) * (b - t)
        if first < second:
            low = t
        else:
            high = t
    t = (low + high) / 2
    return (t, a-t, b-t, 1-a-b+t), high-low

def tv(p, q):
    return sum(abs(x-y) for x, y in zip(p, q)) / 2

if __name__ == "__main__":
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--a", type=D, default=D("0.5"), help="first row mass")
    ap.add_argument("--b", type=D, default=D("0.5"), help="first column mass")
    ap.add_argument("--kernel", type=D, nargs=4, default=list(map(D, ["3","1","1","3"])))
    ap.add_argument("--candidate", type=D, nargs=4)
    args = ap.parse_args()
    if not (0 < args.a < 1 and 0 < args.b < 1 and all(k > 0 for k in args.kernel)):
        ap.error("require positive masses and kernel entries")
    plan, width = reference(args.a, args.b, args.kernel)
    print("optimal plan:", " ".join(map(str, plan)))
    print("decimals used:", getcontext().prec, "final bisection width:", width)
    if args.candidate is not None:
        print("candidate plan TV:", tv(args.candidate, plan))
    elif (args.a,args.b,args.kernel)==(D(".5"),D(".5"),list(map(D,["3","1","1","3"]))):
        assert tv(plan, (D(".375"),D(".125"),D(".125"),D(".375"))) < D("1e-60")
