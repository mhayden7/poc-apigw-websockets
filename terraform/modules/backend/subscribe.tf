resource "aws_lambda_function" "subscribe" {
  filename = "../subscribe.zip"
  function_name = "${var.config.project}_subscribe"
  runtime = "python3.13"
  handler = "subscribe.lambda_handler"
  role = aws_iam_role.lambda_role.arn
  source_code_hash = filebase64sha256("../subscribe.zip")
  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.websocket_test.name
      management_url = "https://${aws_apigatewayv2_api.websocket.id}.execute-api.${var.config.region}.amazonaws.com/${aws_apigatewayv2_stage.stage.name}"
    }
  }
}

resource "aws_apigatewayv2_route" "subscribe" {
  api_id = aws_apigatewayv2_api.websocket.id
  route_key = "subscribe"
  target = "integrations/${aws_apigatewayv2_integration.subscribe.id}"
}

resource "aws_lambda_permission" "apigw_invoke_subscribe" {
  statement_id = "AllowAPIGatewayInvoke"
  action = "lambda:InvokeFunction"
  function_name = aws_lambda_function.subscribe.function_name
  principal = "apigateway.amazonaws.com"
  source_arn = "${aws_apigatewayv2_api.websocket.execution_arn}/*/*"
}

resource "aws_apigatewayv2_integration" "subscribe" {
  api_id = aws_apigatewayv2_api.websocket.id
  integration_type =  "AWS_PROXY"
  connection_type = "INTERNET"
  content_handling_strategy = "CONVERT_TO_TEXT"
  integration_method = "POST"
  integration_uri = aws_lambda_function.subscribe.invoke_arn
}
