
provider "aws" {
  region = "eu-central-1"
}

resource "aws_s3_bucket" "receipt_html" {
  bucket = "denizstore-receipt-html"

  website {
    index_document = "form.html"
  }

  acl = "public-read"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = "*",
        Action = "s3:GetObject",
        Resource = "arn:aws:s3:::denizstore-receipt-html/*"
      }
    ]
  })
}

resource "aws_dynamodb_table" "receipts" {
  name         = "Receipts"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "email"
  range_key    = "timestamp"

  attribute {
    name = "email"
    type = "S"
  }

  attribute {
    name = "timestamp"
    type = "S"
  }
}

resource "aws_iam_role" "lambda_exec" {
  name = "lambda-receipt-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Principal = {
        Service = "lambda.amazonaws.com"
      },
      Effect = "Allow",
      Sid    = ""
    }]
  })
}

resource "aws_iam_role_policy_attachment" "basic_lambda" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "lambda_dynamodb" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess"
}

resource "aws_iam_role_policy_attachment" "lambda_ses" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSESFullAccess"
}

resource "aws_lambda_function" "send_receipt" {
  function_name = "SendTestEmail"
  runtime       = "python3.11"
  role          = aws_iam_role.lambda_exec.arn
  handler       = "lambda.lambda_handler"
  filename      = "lambda.zip"
  source_code_hash = filebase64sha256("lambda.zip")
}

resource "aws_apigatewayv2_api" "receipt_api" {
  name          = "ReceiptAPI"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_integration" "lambda_integration" {
  api_id           = aws_apigatewayv2_api.receipt_api.id
  integration_type = "AWS_PROXY"
  integration_uri  = aws_lambda_function.send_receipt.invoke_arn
}

resource "aws_apigatewayv2_route" "send_receipt_route" {
  api_id    = aws_apigatewayv2_api.receipt_api.id
  route_key = "POST /send-receipt"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
}

resource "aws_apigatewayv2_stage" "prod" {
  api_id      = aws_apigatewayv2_api.receipt_api.id
  name        = "prod"
  auto_deploy = true
}

resource "aws_lambda_permission" "allow_api_gateway" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.send_receipt.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.receipt_api.execution_arn}/*/*"
}
