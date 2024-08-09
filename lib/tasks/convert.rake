require 'rake'

# lib/tasks/convert_postman.rake

namespace :convert do
  desc 'Convert Postman collection to OpenAPI'
  task :postman_to_openapi, [:postman_file, :output_file] do |t, args|
    # Set default values if arguments are not provided
    postman_file = args[:postman_file] || 'path/to/your/postman_collection.json'
    output_file = args[:output_file] || 'path/to/your/swagger.yml'

    # Initialize the converter with the provided Postman file path
    converter = PostmanToSwagger::Converter.new(postman_file)
    converter.generate_openapi(output_file)

    puts "Conversion completed. OpenAPI specs saved to #{output_file}"
  end
end
