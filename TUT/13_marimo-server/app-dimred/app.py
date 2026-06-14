import marimo

app = marimo.App()

@app.cell
def _():
    import marimo as mo
    import numpy as np
    import matplotlib.pyplot as plt
    return mo, np, plt


@app.cell
def _(mo):
    noise = mo.ui.slider(0.0, 2.0, value=0.5)

    mo.md("# Dimensionality Reduction Explorer")

    noise
    return noise,


@app.cell
def _(np, noise):
    x = np.linspace(0, 10, 2000)
    y = np.sin(x) + np.random.normal(0, noise.value, size=len(x))
    return x, y


@app.cell
def _(plt, x, y):
    fig, ax = plt.subplots()
    ax.plot(x, y, alpha=0.7)
    ax.set_title("Noisy structure")
    ax.grid(True, alpha=0.3)

    fig
    return fig,


if __name__ == "__main__":
    app.run()