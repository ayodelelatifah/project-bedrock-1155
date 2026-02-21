resource "aws_s3_bucket" "state_bucket" {
  bucket = "bedrock-assets-1155"

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_versioning" "state_versioning" {
  bucket = aws_s3_bucket.state_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = aws_s3_bucket.state_bucket.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.processor.arn
    events              = ["s3:ObjectCreated:*"]
  }

  depends_on = [aws_lambda_permission.allow_s3]
}

resource "aws_iam_user_policy_attachment" "gorgeous_s3_access" {
  user       = "gorgeous" # Or the name of the user from the ARN
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}