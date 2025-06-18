# Gunakan `python:3.11.4` sebagai base image
FROM python:3.11.4

# Set direktori di dalam container
WORKDIR /api

# Copy semua file ke dalam container
COPY . .

# Install dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Menjalankan script api.py
CMD ["python", "api.py"]


