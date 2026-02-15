provider "aws" {

  region = "eu-west-1"

}



# Create S3 bucket for static website hosting

resource "aws_s3_bucket" "site" {

  bucket = "luffiii-site-s3" # must be globally unique



  website {

    index_document = "index.html"

    error_document = "error.html"

  }



  tags = {

    Name = "luffiii-terra-s3-website"

  }

}



# Disable the default public access block so policy can work

resource "aws_s3_bucket_public_access_block" "allow_public" {

  bucket                  = aws_s3_bucket.site.id

  block_public_acls       = false

  block_public_policy     = false

  ignore_public_acls      = false

  restrict_public_buckets = false

}



# Add a bucket policy to allow public read access

resource "aws_s3_bucket_policy" "public_read_policy" {

  bucket = aws_s3_bucket.site.id



  policy = jsonencode({

    Version = "2012-10-17"

    Statement = [

      {

        Sid       = "PublicReadGetObject"

        Effect    = "Allow"

        Principal = "*"

        Action    = "s3:GetObject"

        Resource  = "${aws_s3_bucket.site.arn}/*"

      }

    ]

  })

}



# Upload index.html to bucket

resource "aws_s3_object" "index" {

  bucket       = aws_s3_bucket.site.id

  key          = "index.html"

  source       = "${path.module}/index.html"

  content_type = "text/html"

}



output "website_url" {

  value       = aws_s3_bucket.site.website_endpoint

  description = "Public website endpoint for the S3 static site"

}
