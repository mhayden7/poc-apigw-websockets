resource "aws_apigatewayv2_route" "websocket_disconnect_route" {
  api_id = aws_apigatewayv2_api.websocket.id
  route_key = "$disconnect"
  target = "integrations/${aws_apigatewayv2_integration.disconnect.id}"
}

resource "aws_apigatewayv2_integration" "disconnect" {
  api_id = aws_apigatewayv2_api.websocket.id
  integration_type =  "AWS"
  integration_method = "POST"
  integration_uri = "arn:aws:apigateway:us-east-1:sqs:path/390449960040/${aws_sqs_queue.disconnect.name}"
  credentials_arn = aws_iam_role.apigw_role.arn
  passthrough_behavior = "NEVER"

  request_parameters = {
    "integration.request.header.Content-Type" = "'application/x-www-form-urlencoded'"
  }  

request_templates = {
  "$default" = "Action=SendMessage&MessageBody=$util.urlEncode($context.connectionId)"
}   
}

data "aws_iam_policy_document" "disconnect_queue_access" {
  statement {
    effect = "Allow"
    principals {
      type = "Service"
      identifiers = ["apigateway.amazonaws.com"]
    }
    actions = ["sqs:SendMessage"]
    resources = [aws_sqs_queue.disconnect.arn]
  }
}

resource "aws_sqs_queue" "disconnect" {
  name = "${var.config.project}_disconnect"
  message_retention_seconds = 900
  visibility_timeout_seconds = 60
  delay_seconds = 330
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.disconnect_dlq.arn
    maxReceiveCount = 5
  })
}

resource "aws_sqs_queue_policy" "disconnect_queue_access" {
  queue_url = aws_sqs_queue.disconnect.id
  policy = data.aws_iam_policy_document.disconnect_queue_access.json  
}

resource "aws_sqs_queue" "disconnect_dlq" {
  name = "${var.config.project}_disconnect_dlq"
  message_retention_seconds = 1209600 # 14 days
}

resource "aws_lambda_function" "disconnect" {
  filename = "../disconnect.zip"
  function_name = "${var.config.project}_disconnect"
  runtime = "python3.13"
  handler = "disconnect.lambda_handler"
  role = aws_iam_role.lambda_role.arn
  source_code_hash = filebase64sha256("../disconnect.zip")
  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.websocket_test.name
    }
  }
}

resource "aws_lambda_permission" "sqs_invoke_disconnect" {
  statement_id = "AllowAPIGatewayInvoke"
  action = "lambda:InvokeFunction"
  function_name = aws_lambda_function.disconnect.function_name
  principal = "sqs.amazonaws.com"
  source_arn = "${aws_apigatewayv2_api.websocket.execution_arn}/*/*"
}

resource "aws_lambda_event_source_mapping" "disconnect" {
  event_source_arn = aws_sqs_queue.disconnect.arn
  enabled = true
  function_name = aws_lambda_function.disconnect.function_name
}
