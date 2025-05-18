# Cloud Programming – Receipt Generator Platform

This project was built as part of the Cloud Programming course at IU, showcasing how AWS services can be integrated to create a fully functional receipt system that:

- Hosts an HTML form online
- Sends personalized receipt emails
- Stores user and purchase data in a database
- Issues conditional discount codes based on the purchase amount

---

## Features

- **Frontend:** HTML + JavaScript form hosted on Amazon S3
- **Backend:** AWS Lambda (Python) function triggered by API Gateway
- **Data Storage:** Amazon DynamoDB table to store customer data and purchase history
- **Email Service:** Amazon SES to send rich HTML receipts with personalized content
- **Infrastructure as Code:** Terraform configuration to provision all AWS services

---

## File Structure

| File         | Description |
|--------------|-------------|
| `form.html`  | The public shopping receipt form (hosted on S3) |
| `lambda.py`  | Python script executed by AWS Lambda to process form data |
| `lambda.zip` | Zipped deployment package containing `lambda.py` |
| `main.tf`    | Terraform configuration to automate AWS resource provisioning |

---

## Workflow

1. **User** opens the form hosted on S3
2. **Form** sends data via POST to API Gateway
3. **API Gateway** triggers the Lambda function
4. **Lambda**:
   - Stores data in DynamoDB
   - Sends receipt via SES
   - Calculates discount if eligible
5. **User** receives styled HTML receipt via email with discount codes (if eligible)

---

## Discount Logic

- **≥ €10** → Gets **10% OFF** code: `DENIZSTORE-10%`
- **≥ €20** → Gets **20% OFF** code: `DENIZSTORE-20%`

Discount codes are also validated in the form and shown if applied.

---

## AWS Services Used

- Amazon S3
- AWS Lambda
- Amazon API Gateway
- Amazon DynamoDB
- Amazon SES
- IAM
- CloudWatch
- (Optional) Terraform

---

## Notes

- This setup runs in the **`eu-central-1` (Frankfurt)** AWS region.
- You can test the HTML form by uploading it to any public S3 bucket with static website hosting enabled.
- All infrastructure can be recreated by running `terraform apply` (if configured).

---

## Author

**Deniz Lahi**  

Student at IU International University of Applied Sciences  
Course: Cloud Programming  
Year: 2025
