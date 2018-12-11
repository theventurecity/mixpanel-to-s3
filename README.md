# mixpanel-to-s3.py

## Description
A Dockerized Python script that will export all raw events from MixPanel API and upload to an AWS S3 Bucket

## Requirements
- python 3 and pip 
- Docker (optional)
- Python packages listed in `requirements.txt`

## Parameters
All parameters are expected as Environment Variables:
- `AWS_REGION`: set your AWS region example: `us-east-1`
- `AWS_ACCESS_KEY_ID`: set your AWS IAM access key ID
- `AWS_SECRET_ACCESS_KEY`: set your AWS IAM Secret access key
- `S3_BUCKET`: set name of your target S3 bucket
- `S3_PATH`: set the base PATH inside your S3 bucket... do not put a leading `/` example: `my/mixpanel/data`
- `MIXPANEL_API_SECRET`: Your Mixpanel API secret
- `START_DATE`" (Optional) a date from which start exporting events in ISO format `YYYY-MM-DD` example: `2018-11-01`

## Running on local Docker
1. Edit `.env` file and set the proper values for each environment variable
2. Create Docker image with `docker build --rm -f "Dockerfile" -t mixpanel-to-s3:latest .`
3. Run Docker image with `docker run --rm -it --env-file .env mixpanel-to-s3:latest`

## Running without Docker
1. set every environment variables listed in `.env` file with your own values using `export VAR=VALUE` for each.
2. install python package requirements (only needed once) with `pip install -r requirements.txt`
3. run with `python3 mixpanel-to-s3.py`

## Implementation
The script will:
1. Starting on Date `START_DATE` or (default) since last 5 days
2. will fetch the MixPanel Raw events in JSON format into a single compressed (gzip), one per day with name `rawEvents_{isodate}.json.gz`
3. Each file will be uploaded, using S3 Multipart Upload to your specified `S3_BUCKET/S3_PATH` under a folder with the following structure: `year=YYYY/month=MM/day=DD`

Example:
given date is 2018-11-01, then the final S3 file will be under: `s3://S3_BUCKET/S3_PATH/year=2018/month=11/day=01/rawEvents_2018-11-01.json.gz`
This folder naming convention make it easier to be queried with tools like Hive or AWS glue, in a way that data will be partitioned by year, month and day.

