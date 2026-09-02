### Setup Role

data "aws_iam_policy_document" "lambda_assume_role" {
    statement {
      effect = "Allow"
      principals {
        type = "Service"
        identifiers = ["lambda.amazonaws.com"]
      }
      actions = ["sts:AssumeRole"]
    }
}
  resource "aws_iam_role" "lambda_role" {
      name = "${var.config.project}_lambda"
      assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
  }


data "aws_iam_policy_document" "logging" {
  statement {
    effect = "Allow"
    actions = ["logs:CreateLogGroup"]
    resources = ["arn:aws:logs:*:*:*"]
  }
  statement {
    effect = "Allow"
    actions = ["logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["arn:aws:logs:*:*:*"]
  }
}
    resource "aws_iam_policy" "logging" {
      name = "${var.config.project}_logging"
      policy = data.aws_iam_policy_document.logging.json
    }
    resource "aws_iam_role_policy_attachment" "logging" {
      role = aws_iam_role.lambda_role.name
      policy_arn = aws_iam_policy.logging.arn
    }


data "aws_iam_policy_document" "dynamodb_access" {
  statement {
    effect = "Allow"
    actions = ["dynamodb:Scan", "dynamodb:GetItem", "dynamodb:DeleteItem", "dynamodb:PutItem", "dynamodb:Query", "dynamodb:UpdateItem"]
    resources = [aws_dynamodb_table.websocket_test.arn, "${aws_dynamodb_table.websocket_test.arn}/index/*"]
  }
}
    resource "aws_iam_policy" "dynamodb_access" {
    name = "${var.config.project}_dynamodb_access"
    policy = data.aws_iam_policy_document.dynamodb_access.json
    }
    resource "aws_iam_role_policy_attachment" "dynamodb_access" {
    role = aws_iam_role.lambda_role.name
    policy_arn = aws_iam_policy.dynamodb_access.arn
    }



data "aws_iam_policy_document" "apigw_access" {
  statement {
    effect = "Allow"
    actions = ["execute-api:ManageConnections"]
    resources = ["arn:aws:execute-api:us-east-1:*:*/*/POST/@connections/*"]
  }
}
    resource "aws_iam_policy" "apigw_access" {
    name = "${var.config.project}_apigw_access"
    policy = data.aws_iam_policy_document.apigw_access.json
    }
    resource "aws_iam_role_policy_attachment" "apigw_access" {
    role = aws_iam_role.lambda_role.name
    policy_arn = aws_iam_policy.apigw_access.arn
    }


data "aws_iam_policy_document" "sqs_access" {
    statement {
        effect = "Allow"
        actions = ["sqs:ChangeMessageVisibility", "sqs:DeleteMessage", "sqs:GetQueueAttributes", "sqs:ReceiveMessage"]
        resources = [aws_sqs_queue.disconnect.arn]
    }
}
    resource "aws_iam_policy" "sqs_access" {
        name = "${var.config.project}_sqs_access"
        policy = data.aws_iam_policy_document.sqs_access.json
    }
    resource "aws_iam_role_policy_attachment" "sqs_access" {
      role = aws_iam_role.lambda_role.name
      policy_arn = aws_iam_policy.sqs_access.arn
    }
