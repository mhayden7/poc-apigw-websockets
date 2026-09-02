resource "aws_lambda_function" "publish" {
  filename = "../publish.zip"
  function_name = "${var.config.project}_publish"
  runtime = "python3.13"
  handler = "publish.lambda_handler"
  role = aws_iam_role.lambda_role.arn
  source_code_hash = filebase64sha256("../publish.zip")
  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.websocket_test.name
      management_url = "https://${aws_apigatewayv2_api.websocket.id}.execute-api.${var.config.region}.amazonaws.com/${aws_apigatewayv2_stage.stage.name}"
    }
  }
}

resource "aws_apigatewayv2_route" "publish" {
  api_id = aws_apigatewayv2_api.websocket.id
  route_key = "publish"
  target = "integrations/${aws_apigatewayv2_integration.publish.id}"
}

resource "aws_lambda_permission" "apigw_invoke_publish" {
  statement_id = "AllowAPIGatewayInvoke"
  action = "lambda:InvokeFunction"
  function_name = aws_lambda_function.publish.function_name
  principal = "apigateway.amazonaws.com"
  source_arn = "${aws_apigatewayv2_api.websocket.execution_arn}/*/*"
}

resource "aws_apigatewayv2_integration" "publish" {
  api_id = aws_apigatewayv2_api.websocket.id
  integration_type =  "AWS_PROXY"
  connection_type = "INTERNET"
  content_handling_strategy = "CONVERT_TO_TEXT"
  integration_method = "POST"
  integration_uri = aws_lambda_function.publish.invoke_arn
}
