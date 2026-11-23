# ECR repository for the app image. Tags are immutable: a commit's image can never be replaced.

resource "aws_ecr_repository" "app" {
  name                 = local.ecr.name
  image_tag_mutability = "IMMUTABLE"
  force_delete         = local.ecr.force_delete

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }
}

resource "aws_ecr_lifecycle_policy" "app" {
  repository = aws_ecr_repository.app.name

  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Keep the last ${local.ecr.keep_images} images"
      selection = {
        tagStatus   = "any"
        countType   = "imageCountMoreThan"
        countNumber = local.ecr.keep_images
      }
      action = { type = "expire" }
    }]
  })
}
