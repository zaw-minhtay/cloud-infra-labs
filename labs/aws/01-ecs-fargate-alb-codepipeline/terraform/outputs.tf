output "app_url" {
  description = "Open this in a browser or use it with curl"
  value       = "http://${aws_lb.main.dns_name}"
}

output "ecr_repository_url" {
  description = "Where the pipeline pushes the app image"
  value       = aws_ecr_repository.app.repository_url
}

output "codeconnection_name" {
  description = "Finish this connection once in the console (setup/3-pipeline.md)"
  value       = aws_codeconnections_connection.github.name
}

output "pipeline_name" {
  value = aws_codepipeline.app.name
}

output "ecs_cluster_name" {
  value = aws_ecs_cluster.main.name
}

output "ecs_service_name" {
  value = aws_ecs_service.app.name
}

output "aurora_cluster_identifier" {
  value = aws_rds_cluster.main.cluster_identifier
}

output "aurora_writer_identifier" {
  value = aws_rds_cluster_instance.writer.identifier
}

output "aurora_reader_identifier" {
  value = aws_rds_cluster_instance.reader.identifier
}
