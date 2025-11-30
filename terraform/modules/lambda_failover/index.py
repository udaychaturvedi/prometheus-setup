import boto3
import os

route53 = boto3.client('route53')

def lambda_handler(event, context):
    zone_id       = os.environ['ZONE_ID']
    record_name   = os.environ['RECORD_NAME']
    standby_ip    = os.environ['STANDBY_IP']
    ttl           = 60

    # UPSERT = replace or create
    change_batch = {
        'Comment': 'Automatic failover to standby Prometheus instance',
        'Changes': [
            {
                'Action': 'UPSERT',
                'ResourceRecordSet': {
                    'Name': record_name,
                    'Type': 'A',
                    'TTL': ttl,
                    'ResourceRecords': [{'Value': standby_ip}]
                }
            }
        ]
    }

    resp = route53.change_resource_record_sets(
        HostedZoneId=zone_id,
        ChangeBatch=change_batch
    )

    return {
        "status": "success",
        "changed_to": standby_ip,
        "change_id": resp.get('ChangeInfo', {}).get('Id')
    }
