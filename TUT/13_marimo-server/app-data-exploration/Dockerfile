FROM python:3.12-slim

RUN pip install marimo numpy matplotlib

WORKDIR /app
COPY app.py .

EXPOSE 8080

CMD ["marimo", "run", "app.py", "--host", "0.0.0.0", "--port", "8080"]