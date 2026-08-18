FROM python:3.12-slim

WORKDIR /app

COPY exam-source-requirements.txt .

RUN pip install --no-cache-dir -r exam-source-requirements.txt

COPY exam-source-app.py .
COPY exam-source-config.json /app/config/exam-source-config.json

ENV PORT=5000
ENV CONFIG_PATH=/app/config/exam-source-config.json

EXPOSE 5000

CMD ["gunicorn", "--bind", "0.0.0.0:5000", "exam-source-app:app"]
