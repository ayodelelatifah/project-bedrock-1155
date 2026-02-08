import urllib.parse

def lambda_handler(event, context):
    # Get the bucket name and the file name from the event
    bucket = event['Records'][0]['s3']['bucket']['name']
    key = urllib.parse.unquote_plus(event['Records'][0]['s3']['object']['key'], encoding='utf-8')
    
    print(f"Image received: {key} from bucket: {bucket}")
    return {
        'status': 'success',
        'file': key
    }