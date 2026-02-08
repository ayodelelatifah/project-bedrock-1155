# IAM Role for Lambda
resource "aws_iam_role" "lambda_exec" {
  name = "bedrock-asset-processor-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

# Standard Logging Policy
resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# The Lambda Function
resource "aws_lambda_function" "processor" {
  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  function_name    = "bedrock-asset-processor"
  role             = aws_iam_role.lambda_exec.arn
  handler          = "index.lambda_handler"
  runtime          = "python3.9"

  environment {
    variables = {
      PROJECT = var.project_name
    }
  }
}

# Permission for S3 to invoke Lambda
resource "aws_lambda_permission" "allow_s3" {
  statement_id  = "AllowS3Invoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.processor.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.state_bucket.arn
}

data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "index.py"
  output_path = "lambda_function.zip"
}