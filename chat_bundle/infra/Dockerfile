FROM python:3.11-slim
WORKDIR /app
COPY backend /app/backend
COPY infra/requirements.txt /app/
RUN pip install -r infra/requirements.txt
CMD ["uvicorn","backend.main:app","--host","0.0.0.0","--port","8000"]