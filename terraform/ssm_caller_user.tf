# IAM user and scoped policy for callers who are allowed to start SSM sessions
# This creates an IAM user (console/CLI) and an IAM policy that allows StartSession only
# for instances that have the tag Key=SSMAccess,Value=true. After creating the user, generate
# access keys in the console or with aws iam create-access-key. Do NOT commit access keys.

resource "aws_iam_user" "ssm_caller" {
  name = "${local.name_prefix}-ssm-caller"
  path = "/"
}

data "aws_caller_identity" "current" {}

resource "aws_iam_policy" "ssm_caller_policy" {
  name        = "${local.name_prefix}-ssm-caller-policy"
  description = "Allow StartSession only for instances tagged SSMAccess=true"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = "AllowSSMStartOnTaggedInstances",
        Effect = "Allow",
        Action = [
          "ssm:StartSession",
          "ssm:TerminateSession",
          "ssm:DescribeInstanceInformation"
        ],
        Resource = "*",
        Condition = {
          StringEquals = {
            "ec2:ResourceTag/SSMAccess" = "true"
          }
        }
      },
      {
        Sid    = "AllowSSMMessagesChannels",
        Effect = "Allow",
        Action = [
          "ssmmessages:CreateControlChannel",
          "ssmmessages:CreateDataChannel",
          "ssmmessages:OpenControlChannel",
          "ssmmessages:OpenDataChannel"
        ],
        Resource = "*"
      },
      {
        Sid    = "DescribeNeededResources",
        Effect = "Allow",
        Action = [
          "ssm:DescribeInstanceInformation",
          "ec2:DescribeInstances"
        ],
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_user_policy_attachment" "attach_ssm_policy" {
  user       = aws_iam_user.ssm_caller.name
  policy_arn = aws_iam_policy.ssm_caller_policy.arn
}

# Note: We intentionally DO NOT create an access key here to avoid storing secrets in terraform state.
# Generate an access key for the user in the console (IAM -> Users -> user -> Security credentials) or
# run the CLI as an admin: aws iam create-access-key --user-name ${local.name_prefix}-ssm-caller

output "ssm_caller_username" {
  value = aws_iam_user.ssm_caller.name
}
