resource "aws_cloudformation_stack" "serverless_fixity_solution" {
  name         = "fixity-${local.is_staging ? "staging" : "production"}"
  template_url = "https://awsi-megs-guidances-us-east-1.s3.amazonaws.com/serverless-fixity-for-digital-preservation-compliance/latest/serverless-fixity-for-digital-preservation-compliance.template"
  parameters = {
    # The fixity stack won't deploy without an email address, so we'll give it a black hole address
    # that we'll unsubscribe manually as soon as the stack finishes deploying
    Email                 = "fixity-blackhole@mailinator.com"
    VendorAccountRoleList = ""
  }
  capabilities = ["CAPABILITY_IAM", "CAPABILITY_NAMED_IAM", "CAPABILITY_AUTO_EXPAND"]
}

# Reference the state machine created by the CloudFormation stack
data "aws_sfn_state_machine" "fixity_state_machine" {
  name = aws_cloudformation_stack.serverless_fixity_solution.outputs.StateMachineName
}
