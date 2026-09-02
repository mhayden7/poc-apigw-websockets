resource "aws_apigatewayv2_route" "websocket_connect_route" {
  api_id = aws_apigatewayv2_api.websocket.id
  route_key = "$connect"
  target = "integrations/${aws_apigatewayv2_integration.connect.id}"
  authorization_type = "CUSTOM"
  authorizer_id = aws_apigatewayv2_authorizer.authorizer.id
}

resource "aws_lambda_function" "connect" {
  filename = "../connect.zip"
  function_name = "${var.config.project}_connect"
  runtime = "python3.13"
  handler = "connect.lambda_handler"
  role = aws_iam_role.lambda_role.arn
  source_code_hash = filebase64sha256("../connect.zip")
  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.websocket_test.name
    }
  }
}

resource "aws_lambda_permission" "apigw_invoke_connect" {
  statement_id = "AllowAPIGatewayInvoke"
  action = "lambda:InvokeFunction"
  function_name = aws_lambda_function.connect.function_name
  principal = "apigateway.amazonaws.com"
  source_arn = "${aws_apigatewayv2_api.websocket.execution_arn}/*/*"
}

resource "aws_apigatewayv2_integration" "connect" {
  api_id = aws_apigatewayv2_api.websocket.id
  integration_type =  "AWS_PROXY"
  connection_type = "INTERNET"
  content_handling_strategy = "CONVERT_TO_TEXT"
  description = "connect_description" 
  integration_method = "POST"
  integration_uri = aws_lambda_function.connect.invoke_arn
}