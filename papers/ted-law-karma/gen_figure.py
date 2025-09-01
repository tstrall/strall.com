import numpy as np
import matplotlib.pyplot as plt

np.random.seed(42)
T = 180
h1 = np.random.normal(0, 1, T).cumsum()/12
h2 = np.random.normal(0, 1, T).cumsum()/12
h3 = np.random.normal(0, 1, T).cumsum()/12

# Coordinated disturbance at t=90
h2[90:] += np.linspace(0, 3, T-90)
h3[90:] += np.linspace(0, 3, T-90)

streams = np.vstack([h1, h2, h3])

window = 20
lambdas = []
for t in range(window, T):
    sub = streams[:, t-window:t]
    cov = np.cov(sub)
    eigvals = np.linalg.eigvalsh(cov)
    lambdas.append(eigvals.max())

plt.figure(figsize=(10,6))
ax1 = plt.subplot(2,1,1)
ax1.plot(h1, label="H1"); ax1.plot(h2, label="H2"); ax1.plot(h3, label="H3")
ax1.axvline(90, linestyle="--")
ax1.set_title("Synthetic Entropy Streams"); ax1.legend()

ax2 = plt.subplot(2,1,2)
ax2.plot(range(window, T), lambdas, label="λ₁")
ax2.axvline(90, linestyle="--")
ax2.set_title("Dominant Eigenvalue of Covariance (λ₁)"); ax2.legend()

plt.tight_layout()
plt.savefig("toy_example_plot.png", dpi=180)
plt.close()
