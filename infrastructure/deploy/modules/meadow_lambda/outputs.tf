output "lambda_function_arn" {
  value = aws_lambda_function.this_lambda_function.arn
}

output "lambda_function_qualified_arn" {
  value = aws_lambda_function.this_lambda_function.qualified_arn
}