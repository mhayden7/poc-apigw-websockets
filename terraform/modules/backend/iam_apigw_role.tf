data "aws_iam_policy_document" "apigw_assume_role" {
    statement {
      effect = "Allow"
      principals {
        type = "Service"
        identifiers = ["apigateway.amazonaws.com"]
      }
      actions = ["sts:AssumeRole"]
    }
}
  resource "aws_iam_role" "apigw_role" {
      name = "${var.config.project}_apigw"
      assume_role_policy = data.aws_iam_policy_document.apigw_assume_role.json
  }

resource "aws_iam_role_policy_attachment" "apigw_logging" {
  role = aws_iam_role.apigw_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonAPIGatewayPushToCloudWatchLogs"
}


data "aws_iam_policy_document" "apigw_sqs_policy" {
  statement {
    effect = "Allow"
    actions = ["sqs:SendMessage", "sqs:GetQueueAttributes"]
    resources = [aws_sqs_queue.disconnect.arn]
  }
}

resource "aws_iam_policy" "apigw_sqs_policy" {
  name = "${var.config.project}_apigw_sqs_policy"
  policy = data.aws_iam_policy_document.apigw_sqs_policy.json
}

resource "aws_iam_role_policy_attachment" "apigw_sqs_policy" {
  role = aws_iam_role.apigw_role.name
  policy_arn = aws_iam_policy.apigw_sqs_policy.arn
}