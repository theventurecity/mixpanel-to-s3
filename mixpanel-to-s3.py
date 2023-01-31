#!/usr/bin/env python

import os
import boto3
import logging
import requests
import re
import datetime
from boto3.s3.transfer import TransferConfig

'''
Read parameters from Environment Variables. Don't forget to set these before running the script.
if using Docker, you can store the environment variables in a file with one ENVVAR=VALUE per line
then run the docker container with --env-file parameter like:
  docker run --env-file file_with_env_vars docker_image_name:tag
'''
#AWS_REGION              = os.environ['AWS_REGION']
#AWS_ACCESS_KEY_ID       = os.environ['AWS_ACCESS_KEY_ID'] # Need an IAM user with read/write access to S3 bucket
#AWS_SECRET_ACCESS_KEY   = os.environ['AWS_SECRET_ACCESS_KEY'] # Need an IAM user with read/write access to S3 bucket
S3_BUCKET               = os.environ['S3_BUCKET']
S3_PATH                 = os.environ['S3_PATH'] # DO NOT use leading or trailing slash /
MIXPANEL_API_SECRET     = os.environ['MIXPANEL_API_SECRET']
DEFAULT_START_DATE      = (datetime.date.today() - datetime.timedelta(days=5)).isoformat() # Default: 5 days ago because Mixpanel events export may have a lag of 5 days behind.
START_DATE              = os.getenv('START_DATE', DEFAULT_START_DATE) # Date expected in ISO format YYYY-MM-DD

''' 
Class: mixpanelS3
Description:
    Helper class to make a Mixpanel API request and stream result directly to an AWS S3 bucket/path using multipart upload
    otherwise, MixPanel API response needs to be loaded into Memory or stored to local file before uploading to S3.
Author: roberto@theventure.city (Roberto Navas)
Last Updated: 2018-10-16
'''
class mixpanelS3:
    PART_SIZE = 5*1024*1024 # 5 Mbytes is minimum part size for S3 multipart uploads.

    def __init__(self, mixpanel_api_secret, logger, use_threads=True):        
        self.api_secret = mixpanel_api_secret
        # self.aws_region = aws_region
        # self.aws_id = aws_id
        # self.aws_secret = aws_secret
        self.use_threads = use_threads
        self.logger = logger
        self.s3_client = boto3.client(
            service_name='s3', 
        )
    
    # See: https://mixpanel.com/help/reference/exporting-raw-data
    def exportEvents(self, from_date, to_date, event=None, where=None, stream=True):
        req_params = {
            'url': 'https://data.mixpanel.com/api/2.0/export/',
            'params': {
                'from_date': from_date,
                'to_date': to_date
            },
            'method': 'GET',
            'headers': {
                'Accept-Encoding': 'gzip'
            },
            'auth': (self.api_secret, ''),
            'stream': stream
        }
        if event:
            req_params['params']['event'] = event
        if where:
            req_params['params']['where'] = event
        response = requests.request(**req_params)
        self.logger.info('Got HTTP response from {}: {}'.format(response.request.url, response.status_code))
        self.logger.info('BODY{}: {}'.format(response.request.url, response.json()))

        return response
    
    def s3MultipartUpload(self, httpResponse, bucket, key):
        if httpResponse.status_code != requests.codes.ok:
            self.logger.error('Nothing to upload! HTTP Status: {}'.format(httpResponse.status_code))
            return
        config = TransferConfig(
            use_threads=self.use_threads, 
            multipart_threshold=self.PART_SIZE,
            multipart_chunksize=self.PART_SIZE
		)
        # resposne.raw from request module returns a file object you can read as new bytes are fetched from the network if stream=True
        with httpResponse.raw as data:
            self.logger.info('Uploading multipart file to S3 bucket: {} key: {}'.format(bucket, key))
            self.s3_client.upload_fileobj(data, bucket, key, Config=config)
            self.logger.info('DONE Uploading multipart file to S3 bucket: {} key: {}'.format(bucket, key))

    def rawEventsToS3(self, from_date, to_date, bucket, key):
        self.exportEvents(
                from_date=from_date,
                to_date=to_date
            )
        self.s3MultipartUpload(
            self.exportEvents(
                from_date=from_date,
                to_date=to_date
            ),
            bucket=bucket,
            key=key
        )

# Set up logging
logging.basicConfig()
log = logging.getLogger('mixpanel-to-s3')
log.setLevel(logging.DEBUG)

# Main...
mixpanel = mixpanelS3(
    MIXPANEL_API_SECRET, 
    logger=log
)
start = datetime.date.fromisoformat(START_DATE)
end   = datetime.date.today() - datetime.timedelta(days=5) # most recent end date is 5 days ago, since Mixpanel may take that long to make events available in API

if end >= start: 
    for day in ( start + datetime.timedelta(days=n) for n in range( (end - start).days + 1 ) ):
        # this will iterate 1 day at a time between start and end dates
        log.info('Exporting date: {}'.format(day.isoformat()))
        mixpanel.rawEventsToS3(
            from_date=day.isoformat(),
            to_date=day.isoformat(),
            bucket=S3_BUCKET,
            key="{path}/{partition}/rawEvents_{isodate}.json.gz".format(
                path=S3_PATH, 
                partition=day.strftime("year=%Y/month=%m/day=%d"), 
                isodate=day.isoformat()
        )
else:
    log.info('Nothing to download or date is too recent START_DATE={}'.format(START_DATE))

log.info('🍺 DONE!')
