output "repository_urls" {
  description = "URLs of the ECR repositories"
  value = {
    for repo in var.repositories : repo => aws_ecr_repository.repositories[repo].repository_url
  }
}

output "repository_arns" {
  description = "ARNs of the ECR repositories"
  value = {
    for repo in var.repositories : repo => aws_ecr_repository.repositories[repo].arn
  }
}

output "repository_registry_ids" {
  description = "Registry IDs of the ECR repositories"
  value = {
    for repo in var.repositories : repo => aws_ecr_repository.repositories[repo].registry_id
  }
}

output "repository_names" {
  description = "Names of the ECR repositories"
  value = {
    for repo in var.repositories : repo => aws_ecr_repository.repositories[repo].name
  }
} 