import boto3
import os 
import time 

def function(event, context):

    provisioned_product_max_ttl_sec = os.environ['PROVISIONED_PRODUCT_MAX_TTL_SEC']
    client = boto3.client('servicecatalog')
    products = client.scan_provisioned_products()
    for p in products:
        


    #for each provisioned product with product1 product_id
        # if current time stamp minus created timestamp greater than 24 hours:
            # terminate product by name
    #signal success
    