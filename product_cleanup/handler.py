import os 
from datetime import datetime, timezone
import uuid
import boto3
import logging

logger = logging.getLogger()
logger.setLevel(logging.INFO)

def function(event, context):
    provisioned_product_max_ttl_sec = os.environ['PROVISIONED_PRODUCT_MAX_TTL_SEC']
    sc_client = boto3.client('servicecatalog')
    response = sc_client.scan_provisioned_products(AccessLevelFilter={'Key': 'Account', 'Value': 'self'})
    print(response)
    while True:
        for item in response['ProvisionedProducts']:
            print(f'item= {item}\n')
            ttl_sec = int((datetime.now(timezone.utc) - item['CreatedTime']).total_seconds())
            print(f'ttl_sec= {ttl_sec}')
            max_ttl_sec = int(provisioned_product_max_ttl_sec)
            print(f'max_ttl_sec= {max_ttl_sec}')
            if ttl_sec > max_ttl_sec:
                terminate_resp = sc_client.terminate_provisioned_product(ProvisionedProductId=item['Id'], TerminateToken=str(uuid.uuid4()))
                print(f'terminating: {terminate_resp}')
        if 'PageToken' in response:
            response = sc_client.scan_provisioned_products(AccessLevelFilter={'Key': 'Account', 'Value': 'self'},PageSize=1,PageToken=response['PageToken'])
        else:
            break

if __name__ == '__main__':
    function('','')