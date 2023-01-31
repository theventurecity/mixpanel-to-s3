FROM ubuntu:jammy

WORKDIR /usr/src/app
COPY requirements.txt ./
RUN apt-get update && \
    apt-get -y upgrade && \
    apt-get install -y --no-install-recommends python3 python3-pip && \
    pip install --no-cache-dir --upgrade pip setuptools wheel && \
    pip install --no-cache-dir -r requirements.txt && \
    # apt-get remove -y --purge gcc g++ python3-dev libgfortran5 && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

COPY *.py ./
RUN chmod +x ./mixpanel-to-s3.py
CMD ["python3", "./mixpanel-to-s3.py"]