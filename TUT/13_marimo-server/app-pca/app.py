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
    freq = mo.ui.slider(1, 10, value=3)
    mo.md("# PCA Explorer")
    freq
    return freq,


@app.cell
def _(np, freq):
    x = np.linspace(0, 10, 2000)
    y = np.sin(freq.value * x)

    fig, ax = plt.subplots()
    ax.plot(x, y)
    ax.set_title("PCA-like structure demo")
    ax.grid(True, alpha=0.3)

    fig
    return fig,


if __name__ == "__main__":
    app.run()