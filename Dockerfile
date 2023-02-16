FROM python:alpine
WORKDIR /usr/src/app
COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt
COPY *.py ./
RUN chmod +x ./mixpanel-to-s3.py
CMD ["python3", "./mixpanel-to-s3.py"]