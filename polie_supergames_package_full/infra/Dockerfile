FROM python:3.10-slim
WORKDIR /app
COPY . /app
RUN pip install -r infra/requirements.txt
CMD ["python3","-m","http.server","8080"]
