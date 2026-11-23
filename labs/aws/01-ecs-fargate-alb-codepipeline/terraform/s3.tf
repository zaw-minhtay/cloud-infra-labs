# Pipeline artifact bucket: the files passed between Source, Build, and Deploy.

resource "aws_s3_bucket" "artifacts" {
  bucket        = local.s3.artifacts.name
  force_destroy = local.s3.artifacts.force_destroy
}

resource "aws_s3_bucket_public_access_block" "artifacts" {
  bucket                  = aws_s3_bucket.artifacts.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "artifacts" {
  bucket = aws_s3_bucket.artifacts.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Bucket policy (policy/s3/artifacts_bucket_policy.json): refuse any request that isn't HTTPS.
resource "aws_s3_bucket_policy" "artifacts" {
  bucket = aws_s3_bucket.artifacts.id
  policy = templatefile(local.s3.artifacts.policy_file, {
    bucket_arn = aws_s3_bucket.artifacts.arn
  })

  depends_on = [aws_s3_bucket_public_access_block.artifacts]
}
