"""NumPy-only example: known entropic optimum, fixed iteration, both probes."""
import numpy as np

x, y = np.linspace(0, 1, 64), np.linspace(0, 1, 128)
K = np.exp(-((x[:, None] - y[None, :]) ** 2) / (2 * 0.25))
Q = K * (0.2 + x[:, None]) * (1.3 - y[None, :])
Q /= Q.sum()                            # planted scaling with its own margins
p, w = Q.sum(axis=1), Q.sum(axis=0)
t = K.max() / K.min()
rho = (t - 1) / (t + 1)
C_row, C_col = [min(k - 1, (1 + t) / 2) for k in K.shape]
u = np.ones(p.size) / p.size
for step in range(1, 101):
    v = w / (K.T @ u)
    Kv = K @ v
    pre = min(1 + C_row, C_col * rho) * 0.5 * abs(u * Kv - p).sum()
    u = p / Kv
    post = C_col * 0.5 * abs(v * (K.T @ u) - w).sum()
    if post < 2.5e-8:
        F = (u[:, None] * K) * v
        actual = 0.5 * abs(F - Q).sum()
        print(f"step {step}, pre {pre:.8g}, post {post:.8g}, observed TV {actual:.8g}")
        assert actual <= min(pre, post) + 1e-14  # empirical float64 comparison
        break
else:
    raise RuntimeError("target not reached")
