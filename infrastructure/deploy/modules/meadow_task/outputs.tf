output "task_definition" {
  value = aws_ecs_task_definition.this_task_definition
}

output "livebook_task_definition" {
  value = aws_ecs_task_definition.this_livebook_task_definition
}
