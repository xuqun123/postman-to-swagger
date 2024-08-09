# frozen_string_literal: true

require "json"
require "yaml"
require "uri"
require_relative "postman_to_swagger/version"

module PostmanToSwagger
  class Error < StandardError; end
  
  class Converter
    def initialize(input_postman_file)
      @postman_data = JSON.parse(File.read(input_postman_file))
    end

    def generate_openapi(output_swagger_file)
      base_url = extract_server_from_url(@postman_data['item'].first['item'].first['request']['url']['raw'])

      swagger = {
        "openapi" => '3.0.1',
        "info" => {
          "title" => @postman_data['info']['name'],
          "version" => @postman_data['info']['version'],
          "description" => @postman_data['info']['description']
        },
        'servers' => [{ 'url' => base_url }],
        "paths" => build_paths
      }

      File.write(output_swagger_file, swagger.to_yaml)
    end

    def build_paths
      paths = {}

      @postman_data['item'].each do |outline_item|
        outline_item['item'].each do |item|
          next unless item['request']

          method = item['request']['method'].downcase.to_s
          path = format_path(item['request']['url'])
          description = item['name']

          paths[path] ||= {}
          paths[path][method] = {
            "description" => description,
            "parameters" => extract_parameters(item['request']['url']),
            "requestBody" => extract_request_body(item['request']),
            "responses" => extract_responses
          }
        end
      end

      paths
    end

    private


      def extract_server_from_url(raw_url)
        uri = URI.parse(raw_url)
        
        # Return the scheme and host from the URI, which constitutes the base server URL
        "#{uri.scheme}://#{uri.host}#{":#{uri.port}" if uri.port}"
      end

    def format_path(url)
      # Extract the path from the URL
      uri = URI.parse(url['raw'])
      path = uri.path
    
      # Replace path variables with OpenAPI format
      formatted_path = path.gsub(/\{(\w+)\}/, '{\1}')
    
      formatted_path
    end

    def extract_parameters(url)
      # Convert Postman URL variables into OpenAPI parameters
      parameters = []
      if url['variable']
        url['variable'].each do |var|
          parameters << {
            name: var['key'],
            in: 'path',
            required: true,
            schema: {
              type: 'string'
            }
          }
        end
      end
      parameters
    end

    def extract_request_body(request)
      # Convert Postman request body into OpenAPI requestBody
      if request['body'] && request['body']['mode'] == 'raw'
        {
          "content" => {
            'application/json' => {
              "schema" => {
                "type" => 'object'
              }
            }
          }
        }
      else
        {}
      end
    end

    def extract_responses
      # Placeholder for responses
      {
        '200' => {
          "description" => 'Successful response',
          "content" => {
            'application/json' => {
              "schema" => {
                "type" => 'object'
              }
            }
          }
        }
      }
    end
  end
end
