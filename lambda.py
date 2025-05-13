import json
import boto3
from datetime import datetime, timedelta
from decimal import Decimal

ses = boto3.client('ses')
dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table('Receipts')

def lambda_handler(event, context):
    data = json.loads(event['body'])

    name = data['name']
    email = data['email']
    birthday = data['birthday']
    products = data['products']
    total = Decimal(data['total'])
    
    # Berlin time manually (UTC+2)
    now = datetime.utcnow() + timedelta(hours=2)
    purchase_date = now.strftime('%d/%m/%Y')
    purchase_time = now.strftime('%H:%M:%S')

    # Discount logic
    discount_message = ""
    discount_code = ""
    if total > Decimal('20'):
        discount_code = "DENIZSTORE-20%"
        discount_message = f"<p><strong style='color: red;'>HERE IS A 20% Discount code for your next purchase over €20: {discount_code}</strong></p>"
    elif total > Decimal('10'):
        discount_code = "DENIZSTORE-10%"
        discount_message = f"<p><strong style='color: red;'>HERE IS A 10% Discount code for your next purchase over €10: {discount_code}</strong></p>"

    # Build product list for email
    product_list_html = ''.join([f"<li>{p}</li>" for p in products])

    # Compose HTML email
    html_body = f"""
    <html>
    <head>
      <style>
        body {{ font-family: Arial, sans-serif; color: #333; }}
        .container {{ max-width: 600px; margin: auto; padding: 20px; border: 1px solid #ccc; }}
        .header {{ background-color: #f4f4f4; padding: 10px; text-align: center; font-size: 22px; font-weight: bold; }}
        .total {{ font-weight: bold; margin-top: 10px; }}
      </style>
    </head>
    <body>
      <div class="container">
        <div class="header">🛍️ Your Receipt</div>
        <p>Hello {name},</p>
        <p>Here's what you bought on <strong>{purchase_date} {purchase_time}</strong>:</p>
        <ul>{product_list_html}</ul>
        <p class="total">Total: <strong>€{total}</strong></p>
        <p>Thank you for shopping with us!</p>
        {discount_message}
      </div>
    </body>
    </html>
    """

    # Send Email
    ses.send_email(
        Source='denizlahi1016@gmail.com',
        Destination={'ToAddresses': [email]},
        Message={
            'Subject': {'Data': f"Your Receipt from Deniz Store"},
            'Body': {
                'Html': {'Data': html_body}
            }
        }
    )

    # Save to DynamoDB
    table.put_item(Item={
        'email': email,
        'timestamp': f"{purchase_date} {purchase_time}",
        'name': name,
        'birthday': birthday,
        'products': products,
        'total': total,
        'discount_code': discount_code
    })

    return {
        'statusCode': 200,
        'headers': {
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Headers': 'Content-Type'
        },
        'body': json.dumps({'message': 'Email sent successfully!'})
    }
