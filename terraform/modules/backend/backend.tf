resource "aws_dynamodb_table" "websocket_test" {
  name = "${var.config.project}"
  hash_key = "PK"
  range_key = "SK"
  attribute {
    name = "PK"
    type = "S"
  }
  attribute {
    name = "SK"
    type = "S"
  }
  attribute {
    name = "GSI1PK"
    type = "S"
  }
  attribute {
    name = "GSI2PK"
    type = "S"
  }

  global_secondary_index {
    name = "SessionByConnectionId"
    hash_key = "GSI1PK"
    projection_type = "ALL"
  }

  global_secondary_index {
    name = "SubscriptionByEventType"
    hash_key = "GSI2PK"
    projection_type = "ALL"
  }

  billing_mode = "PAY_PER_REQUEST"
}

resource "aws_apigatewayv2_api" "websocket" {
  name = "poc-apigw-websockets"
  protocol_type = "WEBSOCKET"
  route_selection_expression = "$request.body.action"
}

resource "aws_apigatewayv2_stage" "stage" {
  api_id = aws_apigatewayv2_api.websocket.id
  name = "production"
  default_route_settings {
    throttling_rate_limit = 1000
    throttling_burst_limit = 100
  }
}

# move this to a sub-sequent module to be called after all else
# resource "aws_apigatewayv2_deployment" "websocket" {
#   depends_on = [ aws_apigatewayv2_integration.connect, aws ]
#   api_id = aws_apigatewayv2_api.websocket.id
#   description = "production"

#   lifecycle {
#     create_before_destroy = true
#   }
# }


# $default route
resource "aws_apigatewayv2_route" "websocket_default_route" {
  api_id = aws_apigatewayv2_api.websocket.id
  route_key = "$default"
  target = "integrations/${aws_apigatewayv2_integration.default.id}"
}

resource "aws_lambda_function" "default" {
  filename = "../default.zip"
  function_name = "${var.config.project}_default"
  runtime = "python3.13"
  handler = "default.lambda_handler"
  role = aws_iam_role.lambda_role.arn
  source_code_hash = filebase64sha256("../default.zip")
}

resource "aws_lambda_permission" "apigw_invoke_default" {
  statement_id = "AllowAPIGatewayInvoke"
  action = "lambda:InvokeFunction"
  function_name = aws_lambda_function.default.function_name
  principal = "apigateway.amazonaws.com"
  source_arn = "${aws_apigatewayv2_api.websocket.execution_arn}/*/*"
}

resource "aws_apigatewayv2_integration" "default" {
  api_id = aws_apigatewayv2_api.websocket.id
  integration_type =  "AWS_PROXY"
  connection_type = "INTERNET"
  content_handling_strategy = "CONVERT_TO_TEXT"
  description = "connect_description" 
  integration_method = "POST"
  integration_uri = aws_lambda_function.default.invoke_arn
}


#### Authorizer

resource "aws_lambda_function" "authorizer" {
  filename = "../authorizer.zip"
  function_name = "${var.config.project}_authorizer"
  runtime = "python3.13"
  handler = "authorizer.lambda_handler"
  role = aws_iam_role.lambda_role.arn
  source_code_hash = filebase64sha256("../authorizer.zip")
}

resource "aws_apigatewayv2_authorizer" "authorizer" {
  api_id = aws_apigatewayv2_api.websocket.id
  authorizer_type = "REQUEST"
  authorizer_uri = aws_lambda_function.authorizer.invoke_arn
  identity_sources = ["route.request.querystring.token"]
  name = "websocket-authorizer" 
}

resource "aws_lambda_permission" "apigw_invoke_authorizer" {
  statement_id = "AllowAPIGatewayInvoke"
  action = "lambda:InvokeFunction"
  function_name = aws_lambda_function.authorizer.function_name
  principal = "apigateway.amazonaws.com"
  source_arn = "${aws_apigatewayv2_api.websocket.execution_arn}/*/*"
}