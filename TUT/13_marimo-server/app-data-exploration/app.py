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
    freq = mo.ui.slider(1, 15, value=5)

    mo.md("# Data Exploration App")

    freq
    return freq,


@app.cell
def _(np, freq):
    x = np.linspace(0, 10, 2000)
    y = np.sin(freq.value * x) * np.exp(-0.1 * x)
    return x, y


@app.cell
def _(plt, x, y):
    fig, ax = plt.subplots()
    ax.plot(x, y)
    ax.set_title("Damped signal")
    ax.grid(True, alpha=0.3)

    fig
    return fig,


if __name__ == "__main__":
    app.run()